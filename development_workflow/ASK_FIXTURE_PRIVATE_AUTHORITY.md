# Ask fixture private authority and remount preservation

The DEBUG Ask harness now reuses the existing root regression preference owner. It no longer creates a second suite with a fallback to standard preferences, and it no longer deletes a suite from a per-view disappearance callback. The root remains the cleanup authority. The fixture and Ask view model have stable StateObject ownership inside the existing harness; production Ask architecture, artwork and research are unchanged.

The actual Foundation fixture constructor accepts only explicitly supplied optional preferences. Missing preferences fail without constructing a store. The real measurement store seeds the original single laboratory fixture only when no persisted object exists. Existing valid records, explicit empty/deleted arrays, future/unknown fields, corrupt data and non-data objects are never replaced to create a fixture. Protected storage produces a fixture error. The production measurement store/persistence source and schema are unchanged.

Four genuine Foundation regressions passed: missing authority, exact existing-record/byte preservation across remount, deletion without resurrection, and future/null/corrupt/non-data preservation. The focused run executed four XCTest and selected zero Swift Testing cases. These exercise the actual store and disposable root preference owner; no SDK substitutes are used.

Apple native harness mounting, StateObject retention through modal/navigation/language/background changes, attachment behavior, keyboard/focus and the existing Ask UI vectors remain unexecuted. Those checks are still required; Foundation constructor tests do not certify SwiftUI behavior or all data-deletion requirements. Official MADLAD/device/clinical acceptance remains independently blocked.
