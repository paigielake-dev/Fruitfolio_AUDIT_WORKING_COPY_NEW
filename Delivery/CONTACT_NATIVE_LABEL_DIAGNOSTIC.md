# Contact native-label follow-up

Run46 source 0435fa3 actually passed both FAQ accessibility-size and default-size expansion/collapse journeys, including the unfiltered native all-types accessibility audits. Both Contact tests stopped earlier on the newly introduced `staticTexts.count == 0` assertion: XCTest still exposes one native Button label as StaticText. They therefore did not reach their audits. This is not an accessibility PASS.

The zero-child assertion was an implementation assumption introduced during the earlier label repair, not a founder requirement. The regression test now checks the exact complete email label and absence of nested actionable buttons, captures the actual hierarchy, and retains the existing target-size, Dynamic Type growth, reachability, return-navigation and unconditional `.all` accessibility audit. No accessibility audit type or issue is suppressed. No medical/citation validator is changed.

The shared pill label now uses a multi-child HStack (text and two spacers), rather than a unary wrapper which SwiftUI flattened into a full-shell text rectangle. The real text provides the native Button label; redundant explicit synthesized label overrides are removed. Padding and the unchanged founder-painted pill belong to the surrounding layout, while text keeps its own intrinsic bounds. Actual Run47 verification is required.
