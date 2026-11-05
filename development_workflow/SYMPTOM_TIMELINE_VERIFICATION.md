# Unified symptom observations and calculated descriptions

The graph previously used raw cycle day as its x-coordinate. Different recorded dates with the same cycle day overlapped, and occurrences without an assigned cycle day were counted in the label but never drawn. The production timeline now uses Gregorian civil-day distance in the display time zone, preserving DST spacing and observations before cycle history exists. Every selected recorded occurrence remains a point; missing days do not become zero/absent observations. No connecting trend, severity, ovulation claim, or new prediction is generated.

All logged symptom types start visible; explicit toggles can hide them. A separate readable, expandable list exposes the actual date, symptom and optional cycle day for every selected occurrence. The graph has visible scroll indicators and scalable row labels. Calculated timing descriptions remain separate, named per symptom, and disclose that unlogged days do not establish absence. Existing conservative recurrence rules are unchanged and are not presented as clinically validated statistics.

Plot width is bounded at the width corresponding to 730 day intervals for performance; longer histories are compressed into that span without dropping points. The observation list retains the complete selected history. Invalid nonfinite dates are counted as unplottable instead of substituted with today's date.

Seven new tests exercise the exact production projection: separate months sharing cycle day, no cycle assignment, DST, selection, missing days, empty selection and invalid-date handling. Existing eight trends calculation tests and 36 daily log tests are now included in the portable runner with original assertions. Their synchronous MainActor test signatures were converted to async to avoid a Linux XCTest discovery cast crash.

Linux compiler parsing and Foundation execution do not verify iOS layout, VoiceOver navigation, large text fit, scroll performance or clinical validity. Those remain behind the Apple/runtime and research-review gates.
