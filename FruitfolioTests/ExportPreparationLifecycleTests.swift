import XCTest
@testable import Fruitfolio

@MainActor
final class ExportPreparationLifecycleTests: XCTestCase {
    func testCancelledPreparationCannotPublishLateSensitiveBytesOrOpenDestination() async throws {
        let preparation = FruitfolioExportPreparation()
        let gate = ExportFixtureGate()
        var completions = 0
        preparation.start(operation: { await gate.data() }, completion: { _ in completions += 1 })
        await gate.waitUntilStarted()
        XCTAssertTrue(preparation.isPreparing)
        preparation.cancel()
        XCTAssertFalse(preparation.isPreparing)
        await gate.finish(Data("cancelled-sensitive-fixture".utf8))
        try await Task.sleep(for: .milliseconds(60))
        XCTAssertEqual(completions, 0)
    }

    func testOldCancelledResultCannotReplaceNewPreparedDocument() async throws {
        let preparation = FruitfolioExportPreparation()
        let first = ExportFixtureGate()
        var completedBytes: [Data] = []
        preparation.start(operation: { await first.data() }, completion: {
            if case .success(let bytes) = $0 { completedBytes.append(bytes) }
        })
        await first.waitUntilStarted()
        let expected = Data("current-exact-fixture-bytes".utf8)
        let finished = expectation(description: "Current preparation completed")
        preparation.start(operation: { expected }, completion: {
            if case .success(let bytes) = $0 { completedBytes.append(bytes) }
            finished.fulfill()
        })
        await fulfillment(of: [finished], timeout: 2)
        await first.finish(Data("stale-sensitive-fixture".utf8))
        try await Task.sleep(for: .milliseconds(60))
        XCTAssertEqual(completedBytes, [expected])
        XCTAssertFalse(preparation.isPreparing)
    }

    func testFailedPreparationNeverReturnsSuccessAndReleasesPreparingState() async {
        let preparation = FruitfolioExportPreparation()
        let finished = expectation(description: "Preparation failure returned")
        preparation.start(operation: { throw CocoaError(.fileReadCorruptFile) }, completion: { result in
            switch result {
            case .success: XCTFail("An unreadable store must not produce a prepared export")
            case .failure(let error): XCTAssertEqual((error as NSError).code, CocoaError.fileReadCorruptFile.rawValue)
            }
            finished.fulfill()
        })
        await fulfillment(of: [finished], timeout: 2)
        XCTAssertFalse(preparation.isPreparing)
    }
}

private actor ExportFixtureGate {
    private var didStart = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var resultWaiter: CheckedContinuation<Data, Never>?
    func data() async -> Data {
        await withCheckedContinuation { continuation in
            resultWaiter = continuation
            didStart = true
            startWaiter?.resume(); startWaiter = nil
        }
    }
    func waitUntilStarted() async {
        if didStart { return }
        await withCheckedContinuation { startWaiter = $0 }
    }
    func finish(_ data: Data) { resultWaiter?.resume(returning: data); resultWaiter = nil }
}
