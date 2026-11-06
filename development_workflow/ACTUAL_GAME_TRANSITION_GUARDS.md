# Actual game transition ownership

The actual MainActor controller now rejects invalid option IDs, answers outside the question phase, catch entry before a correct answer, duplicate begin/retry/reveal transitions, and stale question/round/interaction identities before mutation. UI callbacks capture interaction identities and require the visible active scene. Topic/difficulty edits are restricted to setup phases. A cancelled task cannot start a new topic. Backgrounding invalidates outstanding question interactions and provider responses.

The native save destination receives a frozen question/source/citation value and the existing presentation host. The QA harness now follows the legitimate answer → correct feedback → catch intro → begin sequence.

Before fixes, 38 actual controller tests reproduced 12 failed assertions. Final executed suites: 851 portable XCTest, 873 native CPU XCTest, 21 Swift Testing in each run; 60 workflow checks; 311 syntax parses. These tests execute genuine Foundation controller/store code, not a fake Apple SDK.

Apple SDK typechecking, genuine Combine publishing, SwiftUI gesture/background/sheet/focus behavior, physical gameplay and accessibility remain unexecuted on Linux. Official MADLAD weights/inference and clinical translation validation remain blocked. No whole checklist item is certified by this batch. Exact founder copy replacements for 320–322 remain pending clarification.
