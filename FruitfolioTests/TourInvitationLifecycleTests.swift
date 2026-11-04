import XCTest
@testable import Fruitfolio

@MainActor
final class TourInvitationLifecycleTests: XCTestCase {
    private final class Gate {
        var pending: [CheckedContinuation<Void, Never>] = []
        func wait() async { await withCheckedContinuation { pending.append($0) } }
        func releaseFirst() {
            guard !pending.isEmpty else { XCTFail("Expected a suspended invitation"); return }
            pending.removeFirst().resume()
        }
    }

    private func waitForCount(_ count: Int, in gate: Gate) async {
        for _ in 0..<100 where gate.pending.count != count { await Task.yield() }
        XCTAssertEqual(gate.pending.count, count)
    }

    func testDepartureAndReentryDoNotDeliverTheOldInvitationOrCancelTheNewVisit() async {
        let gate = Gate()
        let scheduler = Prompt07TourInvitationScheduler(wait: { await gate.wait() })
        var visits: [String] = []
        scheduler.schedule(eligible: { true }, deliver: { visits.append("old visit") })
        await waitForCount(1, in: gate)
        scheduler.cancel()
        scheduler.schedule(eligible: { true }, deliver: { visits.append("new visit") })
        await waitForCount(2, in: gate)
        gate.releaseFirst()
        for _ in 0..<10 { await Task.yield() }
        XCTAssertTrue(visits.isEmpty)
        XCTAssertTrue(scheduler.isScheduled, "An old completion must not clear the newer visit's owner")
        gate.releaseFirst()
        for _ in 0..<100 where visits.isEmpty { await Task.yield() }
        XCTAssertEqual(visits, ["new visit"])
        XCTAssertFalse(scheduler.isScheduled)
    }

    func testEligibilityIsRecheckedAfterWaitingAndACompletedTutorialNeverReceivesAnInvitation() async {
        let gate = Gate()
        let scheduler = Prompt07TourInvitationScheduler(wait: { await gate.wait() })
        var eligible = true
        var deliveries = 0
        scheduler.schedule(eligible: { eligible }, deliver: { deliveries += 1 })
        await waitForCount(1, in: gate)
        eligible = false
        gate.releaseFirst()
        for _ in 0..<100 where scheduler.isScheduled { await Task.yield() }
        XCTAssertEqual(deliveries, 0)
        XCTAssertFalse(scheduler.isScheduled)
        scheduler.schedule(eligible: { eligible }, deliver: { deliveries += 1 })
        XCTAssertFalse(scheduler.isScheduled)
        XCTAssertTrue(gate.pending.isEmpty)
    }

    func testRepeatedBodyOrBrandingCallbacksScheduleOnlyOneInvitationAndCancelDoesNotAcknowledgeIt() async {
        let gate = Gate()
        let scheduler = Prompt07TourInvitationScheduler(wait: { await gate.wait() })
        var deliveries = 0
        for _ in 0..<10 { scheduler.schedule(eligible: { true }, deliver: { deliveries += 1 }) }
        await waitForCount(1, in: gate)
        scheduler.cancel()
        gate.releaseFirst()
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(deliveries, 0)
        XCTAssertFalse(scheduler.isScheduled)
        scheduler.schedule(eligible: { true }, deliver: { deliveries += 1 })
        await waitForCount(1, in: gate)
        gate.releaseFirst()
        for _ in 0..<100 where deliveries == 0 { await Task.yield() }
        XCTAssertEqual(deliveries, 1)
    }
}
