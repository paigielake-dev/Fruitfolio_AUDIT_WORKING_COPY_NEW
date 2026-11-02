# Source94: guarded modal fit and actual reachability

## Actual failure evidence
Run85 bulk hormone guard failed after14gestures. The calibrated writing viewport was118.3,356.7,206.7,199.3; Cancel was136.3,483.7,170.7,82, leaving9.7pt clipped. The trace repeatedly used12–24pt edge corrections and reversed direction. The actual source does provide a real inner ScrollView; no missing-scroll production failure is inferred for this modal. Unlike the confirmed game question failure, this requires precise target centering and independent largest-control-fit verification.

The test helper now pans the target toward the actual viewport center with a reliable minimum movement and a stationary release, recording actual target/viewport frames each attempt. Complete containment, actual owning writing area and hittability assertions remain unchanged. It never taps a clipped/unhittable proxy or suppresses an audit. The guard target is re-reached after the native audit because an audit may change scroll position.

## Responsive large-text popup controls
The shared popup renderer publishes its measured writing size to child controls. Only accessibility-size controls inside that writing area use compact8pt insets and grapheme wrapping, preserving their actual requested font and minimum82pt target. Normal controls and Contact/FAQ controls outside popups keep their previous geometry. Native UILabel updates its wrap mode when the environment changes. Confirmation popups retain their original normal-width composition; at accessibility sizes they may use the available safe width, with uniform original-art scaling and no extra horizontal inset inside the already-calibrated writing area. No artwork is replaced or distorted; no font is shrunk.

A new actual UIKit/SwiftUI hosting test checks the real Cancel and delete-hormone labels at375/402/440pt phone widths, the largest category, exact requested font, full glyph height and complete action height against the measured original PNG writing viewport. It retains real first-viewport renders, not synthetic screenshots. Actual results are PENDING.

## Stronger actual UI journeys
The normal guard case is retained and a largest-text case is added. A separate real user journey enters a uniquely marked synthetic hormone measurement through the actual entry controls, confirms its date, saves, restarts, cancels the real bulk-deletion dialog, restarts again and reopens that exact original value/unit. It does not seed through a mock store or infer nondeletion from an empty history. The fixture is confined to the owned CI simulator.

Focused guarded-deletion UI tests run before the long inference/regression stages. Health-journey/job budgets allow the added applicable tests to finish; no timed-out case counts as passed. Full existing suites remain enabled.

Fruit Basket audits now explicitly replay the public tour if a previous journey already completed it, so first-tour/rules/home states cannot be silently omitted at either normal or largest text. Mandatory existence assertions remain strict.

Current source94 compilation, native-control rendering and all affected UI results remain PENDING. Do not promote requirements from this implementation record.
