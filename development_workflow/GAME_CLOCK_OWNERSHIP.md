# Game clock lifetime

The owned gameplay task previously promoted its weak controller reference before the loop and kept it alive across every sleep. The task now acquires the controller only after sleep for the current frame. The existing deinitializer can consequently cancel the task when the game is discarded, even if a caller did not invoke the normal leave-screen cleanup. Frame cadence, delta bounds, engine and scoring remain unchanged.

The actual controller regression starts catch mode, waits for an actual clock-driven fruit spawn, then drops its last external strong reference and asserts the weak reference is nil. It does not call the frame driver manually or merely assert deallocation before the task starts. The pre-fix isolated run executed one test and failed the ownership assertion. A bounded two-second wait is a scheduling failure limit, not a performance benchmark. Existing deterministic frame and transition tests remain in the full suites.

Final executed results and log receipts are recorded with the batch and checklist entries. Apple Combine/SwiftUI lifecycle, actual app disappearance, Instruments/device lifetime/performance and official MADLAD inference are not established by this Foundation test.
