# Actual cycle confirmation Apple UI scenarios

Status: source added; Apple typechecking, simulator/device execution, screenshots,
VoiceOver gesture behavior, Dynamic Type rendering, keyboard dismissal and actual
sound playback are **NOT_RUN** on this Linux environment.

The registered DEBUG route `-fruitfolioCycleModalQA` uses the existing shell's
UUID preferences/context suite. Its scenario argument
`-fruitfolioCycleModalQAScenario` accepts:

- `daily-notes`: actual Daily Log view, actual file actor, actual presented popup host.
- `daily-medication`: same view with one explicitly marked fixture medication.
- `onboarding-failure`: actual onboarding view/shared-context merge, actual file
  codec with an explicit rejection boundary for answer saves.
- `prediction-sign`: actual production prediction request factory and global wooden
  popup host, with long explicitly nonclinical layout fixture copy.
- `onboarding-retry`: the same boundary rejects only the first save, then actual
  save-for-exit can acknowledge the file.

`-fruitfolioCycleModalReduceMotion` selects the existing settings override;
`-fruitfolioCycleModalRTL` forces RTL layout, including inside the daily sheet.
This is layout coverage with English fixture/source text, not reviewed Arabic or
other translated output. System accessibility preferences still apply.

Each fixture has its own UUID temporary directory and explicit daily-log owner.
It never reads/writes production cycle files. Fixture readback creates a fresh
production persistence actor, then displays actual saved values and removes the
fixture directory. Deinitialization also attempts cleanup. The Foundation fixture
and failure boundary compile in both portable and real CPU-linked suites; SwiftUI
composition and XCTest UI APIs still require the Apple SDK. DEBUG code is excluded
from release builds.

Four methods were added to the existing Prompt1BModalAccessibilityTests class,
which Tools/verify_prompt1b_mac.sh already selects:

- testDailyLogOwnedExitChoicesUsePresentedPaperAtAccessibilitySize
- testMedicationRemovalUsesOwnedPaperAndPersistsOnlyAfterSavingDay
- testOnboardingFailedAutosaveOffersKeepDiscardOrSaveWithoutLosingSavedAnswers
- testWoodenPredictionUsesSharedMeasuredHostInBothOrientationsAndDirections

The cycle test helper uses the production host’s primary/secondary/tertiary action
identifiers and separately checks each expected label. A source review corrected
an initial label-based selector before Apple execution.

They define36 scenario executions across override on/off, LTR/forced RTL, and the
available keep/discard/save choices, all at Accessibility XXXL. The8wooden-sign
cases additionally include portrait/landscape. Assertions cover
minimum44pt action height and visible scroll bounds, hidden underlying controls,
retained dirty text after Keep, saved-file readback after Save/Discard, removal only
after an acknowledged day save, and screenshot attachments. The Daily Log opens
confirmation while a text editor has been used and asserts the keyboard disappears.

The shared popup host now requests UIKit first-responder resignation on a new popup
identity and when appearing with an existing modal. This prevents hidden text inputs
from continuing to receive keyboard events behind the modal; it does not replay
popup-open audio on host rebuild. This source behavior is not UIKit runtime proof.

On a Mac with the required actual device/simulator llama framework and approved
resources installed, run Tools/verify_prompt1b_mac.sh for the source unit/UI suite
and xcresult evidence. Its existing SDK/framework/model gates still apply. Capture
and inspect the actual screenshots/results; source additions alone do not close
requirements468/471/472 or the full integrated acceptance requirement.
