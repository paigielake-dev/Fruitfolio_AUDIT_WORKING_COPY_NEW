# Reopen and edit existing cycle setup

My Context now exposes each original onboarding question directly. The editor reuses the existing question views and optional-answer controls; it does not restart onboarding, clear completion, duplicate the questionnaire, or require a person to answer every question again. Editing returns to the section index after the selected question's save completes.

The original view model now queues persistence operations in order. Rapid successive changes cannot let an older asynchronous save overwrite the final answer, and completion waits for outstanding writes. Removing a latest-period/current-period answer also clears its dependent date/answer values, instead of retaining stale hidden values.

Explicitly removing an onboarding-reported birth-control, fertility-medication, postpartum, or lactation selection removes the matching shared-context influence. Initial loading alone does not clear independently edited context; unrelated current states are not inferred or erased. Existing provenance-aware cycle-start reconciliation preserves independently recorded history. Closing My Context refreshes the tracker presentations so they read the updated local inputs.

New unit tests cover preserving completed setup, dependent-value removal, rapid-write ordering, and removal of shared-context influence. A simulator journey edits a single answer, restarts, reopens and removes it without repeating the wizard. These changes await actual Run47 compilation and execution and are not marked PASS.
