import XCTest
@testable import Fruitfolio

@MainActor
final class IntroInterruptionRuntimeTests: XCTestCase {
    private func waitForStage(_ stage: Prompt04IntroStage, machine: Prompt04IntroStateMachine,
                              timeout: Duration = .seconds(2)) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while machine.stage != stage, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertEqual(machine.stage, stage)
    }

    func testNormalAndReducedFirstLaunchActuallyExecuteTheSameSixToEightSecondClock() async throws {
        for mode in [Prompt04LaunchMode.firstLaunch, .reducedMotionFirstLaunch] {
            let suite = "Fruitfolio.IntroClock.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let settings = SettingsStore(defaults: defaults); settings.allAudioMuted = true
            let audio = AudioManager(settings: settings)
            defer { audio.resetAllAudio() }
            let machine = Prompt04IntroStateMachine()
            defer { machine.handleBackgrounding(audioManager: audio) }
            var completions = 0
            let start = ContinuousClock.now
            machine.start(mode: mode, audioManager: audio, settings: settings) { first in
                XCTAssertTrue(first); completions += 1
            }
            var observed: [Prompt04IntroStage] = []
            let deadline = start.advanced(by: .seconds(10))
            while machine.stage != .introComplete, ContinuousClock.now < deadline {
                if observed.last != machine.stage { observed.append(machine.stage) }
                try await Task.sleep(for: .milliseconds(20))
            }
            let elapsed = start.duration(to: ContinuousClock.now)
            XCTAssertEqual(machine.stage, .introComplete)
            XCTAssertEqual(completions, 1)
            XCTAssertTrue(machine.hubInteractionEnabled)
            XCTAssertGreaterThanOrEqual(elapsed, .seconds(6))
            XCTAssertLessThanOrEqual(elapsed, .seconds(8), "Actual uninterrupted signature pacing must meet the founder's target")
            XCTAssertTrue(observed.contains(.blankBookSettled))
            XCTAssertTrue(observed.contains(.logoRevealing))
            XCTAssertTrue(observed.contains(.slightlyOpenSettled))
            XCTAssertTrue(observed.contains(.fullyOpenSettled))
            XCTAssertTrue(observed.contains(.rightPageFocusing))
            let report = XCTAttachment(string: "Actual production state machine. Mode=\(mode); elapsed=\(elapsed); stages=\(observed.map(\.rawValue)); completion count=\(completions). This verifies pacing/state execution, not visual frame quality or audible playback.")
            report.name = "Intro_ActualClock_\(mode)"; report.lifetime = .keepAlways; add(report)
        }
    }

    func testBackgroundFreezesProgressAndResumingBlankCoverDoesNotSkipItsUnseenLogo() async throws {
        let suite = "Fruitfolio.IntroPause.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults); settings.allAudioMuted = true
        let audio = AudioManager(settings: settings); defer { audio.resetAllAudio() }
        let machine = Prompt04IntroStateMachine(); defer { machine.handleBackgrounding(audioManager: audio) }
        var completions = 0
        let completion: @MainActor (Bool) -> Void = { _ in completions += 1 }
        machine.start(mode: .firstLaunch, audioManager: audio, settings: settings, completion: completion)
        try await waitForStage(.blankBookArriving, machine: machine)
        let restoration = machine.interruptionRestorationID
        machine.handleBackgrounding(audioManager: audio)
        XCTAssertEqual(machine.stage, .blankBookSettled)
        XCTAssertGreaterThan(machine.interruptionRestorationID, restoration)
        XCTAssertEqual(machine.bookArrivalProgress, 1)
        try await Task.sleep(for: .milliseconds(1800))
        XCTAssertEqual(machine.stage, .blankBookSettled, "Cancelled stage tasks must not advance invisibly")
        XCTAssertEqual(machine.logoRevealProgress, 0)
        XCTAssertFalse(machine.brandedBookResolved)
        XCTAssertEqual(completions, 0)
        machine.resolveAfterInterruption(audioManager: audio, settings: settings, completion: completion, wasFirstLaunch: true)
        try await waitForStage(.logoRevealing, machine: machine)
        XCTAssertFalse(machine.brandedBookResolved, "An unseen logo reveal must execute, not jump straight to the branded cover")
        machine.handleBackgrounding(audioManager: audio)
        XCTAssertEqual(machine.stage, .brandedBookSettled)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(machine.stage, .brandedBookSettled)
        machine.resolveAfterInterruption(audioManager: audio, settings: settings, completion: completion, wasFirstLaunch: true)
        try await waitForStage(.slightlyOpening, machine: machine)
        XCTAssertEqual(machine.bookArrivalProgress, 1)
        XCTAssertTrue(machine.brandedBookResolved)
        XCTAssertEqual(completions, 0)
        let report = XCTAttachment(string: "Actual production task cancellation held blankBookSettled for1.8s beyond the original stage deadline; no completion. Resume executed previously unseen logoRevealing. A second interruption restored brandedBookSettled and resumed slightlyOpening without restarting the blank-book arrival. Original artwork/presentation remains subject to actual simulator visual checks.")
        report.name = "Intro_ActualBackgroundFreezeAndLogicalResume"; report.lifetime = .keepAlways; add(report)
    }
}
