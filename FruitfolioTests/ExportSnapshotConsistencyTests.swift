import XCTest
@testable import Fruitfolio

@MainActor
final class ExportSnapshotConsistencyTests: XCTestCase {
    func testSlowCycleReadCannotMixLaterHealthAndGameEditsIntoAlreadyRequestedExport() async throws {
        let suite = "ExportConsistentSnapshot-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicVolume = 0.23
        let library = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        let context = Prompt27AContextStore(defaults: defaults)
        context.setPersonalHealthField(.thyroid, text: "before export: synthetic reported context")
        let hormones = HormoneMeasurementStore(fileURL: directory.appendingPathComponent("results.json"))
        var measurement = HormoneMeasurement()
        measurement.result = "2.500"; measurement.unit = " original-unit "
        measurement.testDateWasProvided = true
        try hormones.save(measurement)
        let originalContext = context.context
        let originalMeasurements = hormones.measurements
        let game = Prompt28FruitBasketStore(defaults: defaults)
        game.recordQuestion("before-export-question", topic: "nutrition")
        let originalHistory = game.questionHistory.mapValues { $0.sorted() }
        let persistence = BlockedExportCyclePersistence()
        let cycle = Prompt13CycleStore(persistence: persistence)
        let setup = Prompt14CycleOnboardingStore.inMemory(cycleStore: cycle)
        let export = Task { try await FruitfolioPersonalDataExport.capture(
            account: nil, username: "berry_fixture", settings: settings, library: library,
            context: context, hormones: hormones, cycle: cycle, onboarding: setup, fruitBasket: game) }
        await persistence.waitForLoadStart()
        // A real suspension occurs after preparation begins. These are later
        // user edits, not changes the export implementation is allowed to make.
        settings.musicVolume = 0.88
        context.setPersonalHealthField(.thyroid, text: "after export: synthetic later context")
        measurement.result = "9.1250"
        try hormones.save(measurement)
        game.recordQuestion("after-export-question", topic: "nutrition")
        await persistence.releaseLoad()
        let data = try await export.value
        let reopened = try FruitfolioPersonalDataExport.decodeDocument(data)
        XCTAssertEqual(reopened.settings.musicVolume, 0.23)
        XCTAssertEqual(reopened.reportedContext, originalContext)
        XCTAssertEqual(reopened.hormoneMeasurements, originalMeasurements)
        XCTAssertEqual(reopened.fruitBasketQuestionHistory, originalHistory)
        XCTAssertEqual(settings.musicVolume, 0.88)
        XCTAssertEqual(hormones.measurements.first?.result, "9.1250")
        XCTAssertEqual(context.context.personalHealthFields[.thyroid]?.text,
                       "after export: synthetic later context")
        XCTAssertTrue(game.questionHistory["nutrition"]?.contains("after-export-question") == true)
    }
}

private actor BlockedExportCyclePersistence: Prompt13CyclePersistence {
    private var didStart = false
    private var startedWaiter: CheckedContinuation<Void, Never>?
    private var loadWaiter: CheckedContinuation<Void, Never>?
    func load() async -> Prompt13CycleArchive {
        await withCheckedContinuation { continuation in
            loadWaiter = continuation
            didStart = true
            startedWaiter?.resume(); startedWaiter = nil
        }
        return Prompt13CycleArchive()
    }
    func waitForLoadStart() async {
        if didStart { return }
        await withCheckedContinuation { startedWaiter = $0 }
    }
    func releaseLoad() { loadWaiter?.resume(); loadWaiter = nil }
    func save(_ archive: Prompt13CycleArchive) {}
    func erase() {}
}
