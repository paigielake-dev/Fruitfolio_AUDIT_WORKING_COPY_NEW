# Hormone result date semantics

The form collects a test day, not a clinical time of day. `testDate` remains for backwards-compatible Date-based data/UI. New form records and explicit date edits additionally capture `reportedTestDay` (canonical Gregorian civil components), `testDatePrecision = day`, and the entry time zone. The entry zone is not a claim about the laboratory/test location.

The reported civil day is authoritative when present. Display converts that day into the current calendar/time zone without changing it; a skipped civil day that cannot be represented yields no substituted date. Same-day records use a deterministic ID tie rather than implying a laboratory time sequence.

Legacy missing day/precision/entry-zone metadata remains unknown through unrelated edits. The editor lets the user explicitly confirm/correct the displayed date. No original time zone or clinical test time is inferred. Ask attachments supply a date-only Gregorian value and its known/unknown basis, explicitly mark time of day as not recorded, and never forward the compatibility Date's clock as a reported test time.

Foundation tests exercise travel, non-Gregorian calendars, store reconstruction/export, unchanged legacy metadata, same-day ordering, invalid input and the skipped 2011-12-30 Pacific/Apia civil day. These are not Apple UI, physical app-relaunch, clinical interpretation or actual MADLAD tests; those remain unverified.
