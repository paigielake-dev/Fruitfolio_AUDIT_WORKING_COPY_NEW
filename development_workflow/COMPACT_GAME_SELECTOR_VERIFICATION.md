# Compact game selectors

Difficulty and mode selectors now delegate to the existing canonical pill control. Labels wrap and grow; selected labels are bold with the selected accessibility trait, and only unselected artwork dims. The original pill artwork is preserved. The alias no longer owns a separate button or sound cue.

Four new Apple UI scenarios request accessibility XXXL with motion and RTL combinations, checking minimum target geometry, selection changes and growth past the former fixed height. These scenarios have NOT_RUN: no Apple SDK is available. Parser success is not SwiftUI typechecking, visual clipping, contrast, VoiceOver, animation or audio verification.

Feasible checks passed: 712 portable XCTest and 730 actual native CPU XCTest, each with 21 Swift Testing cases; 42 workflow checks; 306 Swift compiler-parsed files; zero actual SwiftSyntax sound-ownership findings. Official MADLAD weights, clinical quality and device execution remain blocked as recorded separately.
