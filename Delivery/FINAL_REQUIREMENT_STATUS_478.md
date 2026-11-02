# Fruitfolio: final source-sprint requirement accounting

All478 original checklist entries are retained below. This is an integrated-source handoff, not full Prompt1B or release acceptance. Exact authoritative-spec mappings remain incomplete where identified. Historical logs are not a new execution of the delivered source. MADLAD inference is excluded for the separate founder sprint.

| Status | Count |
|---|---:|
| PARTIAL | 192 |
| IMPLEMENTED — VERIFICATION PENDING | 70 |
| NOT VERIFIED | 196 |
| PASS | 3 |
| BLOCKED | 1 |
| EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT | 16 |

The three retained narrow PASS decisions use actual historical tests plus byte-identical hormone validation/model and fixture proof. They do not accept the changed store, UI, export, clinical meaning or full application. No new Apple test has executed in this source sprint.

## FF1B-001 — PARTIAL

Create one canonical blur treatment used throughout Fruitfolio.

Original reference: Part 1 / Universal blur system / 1

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioModalBlur.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Full modal state, focus, dismissal and screen-by-screen acceptance is not yet established.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-002 — PARTIAL

Apply identical blur appearance, intensity, opacity, and behavior wherever blur is required.

Original reference: Part 1 / Universal blur system / 2

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioModalBlur.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Full modal state, focus, dismissal and screen-by-screen acceptance is not yet established.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-003 — PARTIAL

Remove inconsistent feature-specific blur implementations.

Original reference: Part 1 / Universal blur system / 3

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioModalBlur.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Full modal state, focus, dismissal and screen-by-screen acceptance is not yet established.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-004 — PARTIAL

Specifically correct the different popup blur treatments in My Encyclopedias and Build Your Own Guide.

Original reference: Part 1 / Universal blur system / 4

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioModalBlur.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Full modal state, focus, dismissal and screen-by-screen acceptance is not yet established.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-005 — PARTIAL

Exception: retain the Hub’s existing tour-specific blur treatment.

Original reference: Part 1 / Universal blur system / 5

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioModalBlur.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-006 — PARTIAL

Ensure blur responds correctly to popup opening, closing, navigation, and other state changes.

Original reference: Part 1 / Universal blur system / 6

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioModalBlur.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Full modal state, focus, dismissal and screen-by-screen acceptance is not yet established.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-007 — PARTIAL

Remove every gray button with a red outline.

Original reference: Part 1 / Universal button system / 1

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Hub/Prompt04HubBridgeView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log

Remaining discrepancies:
- All button destinations, audio synchronization and latency still need complete application-wide verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-008 — PARTIAL

Replace those buttons with the appropriate existing control-pill artwork.

Original reference: Part 1 / Universal button system / 2

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Hub/Prompt04HubBridgeView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log

Remaining discrepancies:
- All button destinations, audio synchronization and latency still need complete application-wide verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-009 — PARTIAL

Apply the same cute button-pop animation across the entire application.

Original reference: Part 1 / Universal button system / 3

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Hub/Prompt04HubBridgeView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log

Remaining discrepancies:
- All button destinations, audio synchronization and latency still need complete application-wide verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-010 — PARTIAL

Include Cycle Tracker buttons, which were specifically identified as inconsistent.

Original reference: Part 1 / Universal button system / 4

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Hub/Prompt04HubBridgeView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log

Remaining discrepancies:
- All button destinations, audio synchronization and latency still need complete application-wide verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-011 — PARTIAL

Keep button interaction, sound, and navigation synchronized.

Original reference: Part 1 / Universal button system / 5

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Hub/Prompt04HubBridgeView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log

Remaining discrepancies:
- All button destinations, audio synchronization and latency still need complete application-wide verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-012 — PARTIAL

Prevent animations from introducing noticeable input lag.

Original reference: Part 1 / Universal button system / 6

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Hub/Prompt04HubBridgeView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/xcode-shared-controls-ui.log

Remaining discrepancies:
- All button destinations, audio synchronization and latency still need complete application-wide verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-013 — PARTIAL

Create a dedicated shared Swift system for popup composition.

Original reference: Part 1 / Universal popup layout system / 13

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-014 — PARTIAL

Remove individual screens’ fragile popup positioning calculations.

Original reference: Part 1 / Universal popup layout system / 14

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-015 — PARTIAL

Measure each popup artwork asset’s actual dimensions and aspect ratio.

Original reference: Part 1 / Universal popup layout system / 15

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-016 — PARTIAL

Determine the usable writing area within each popup.

Original reference: Part 1 / Universal popup layout system / 16

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-017 — PARTIAL

Center text inside its intended writing area.

Original reference: Part 1 / Universal popup layout system / 17

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-018 — PARTIAL

Ensure text wraps without clipping, overflowing, or truncating with ellipses.

Original reference: Part 1 / Universal popup layout system / 18

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-019 — PARTIAL

Support different popup artwork sizes, text lengths, and screen sizes.

Original reference: Part 1 / Universal popup layout system / 19

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-020 — PARTIAL

Position popup buttons and other controls without collisions.

Original reference: Part 1 / Universal popup layout system / 20

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-021 — PARTIAL

Account for Strawberry, Blueberry, and Peach artwork.

Original reference: Part 1 / Universal popup layout system / 21

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-022 — PARTIAL

Preserve character proportions and prevent characters from overlapping text.

Original reference: Part 1 / Universal popup layout system / 22

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-023 — PARTIAL

Adapt popup layouts to Dynamic Type.

Original reference: Part 1 / Universal popup layout system / 23

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-024 — PARTIAL

Prioritize wrapping and responsive layout over reducing font size.

Original reference: Part 1 / Universal popup layout system / 24

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-025 — PARTIAL

Allow only small typography adjustments when necessary.

Original reference: Part 1 / Universal popup layout system / 25

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-026 — PARTIAL

Apply this system to all applicable confirmations, errors, help popups, character dialogue, and feature-specific overlays.

Original reference: Part 1 / Universal popup layout system / 26

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-027 — PARTIAL

Use the appropriate popup opening and closing sounds.

Original reference: Part 1 / Universal popup layout system / 27

Source mappings: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-028 — IMPLEMENTED — VERIFICATION PENDING

Create a separate shared Swift system for decorative artwork.

Original reference: Part 1 / Universal decorative artwork layout system / 1

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift; Fruitfolio/Core/DesignSystems/FruitfolioProtectedDecoration.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Build/xcode-shared-controls-ui.log; Fruitfolio_Verification_Evidence/AppleRuns/Run35/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Build/xcode-shared-controls-ui.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-029 — PARTIAL

Preserve each screen’s founder-approved artwork selection.

Original reference: Part 1 / Universal decorative artwork layout system / 2

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-030 — PARTIAL

Preserve the intended location and relationship of each asset.

Original reference: Part 1 / Universal decorative artwork layout system / 3

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-031 — PARTIAL

Replace brittle absolute coordinates, negative padding, and fixed offsets where necessary.

Original reference: Part 1 / Universal decorative artwork layout system / 4

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-032 — PARTIAL

Position artwork relative to its actual parent container, paper, book, or other intended anchor.

Original reference: Part 1 / Universal decorative artwork layout system / 5

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-033 — PARTIAL

Account for actual image dimensions and aspect ratios.

Original reference: Part 1 / Universal decorative artwork layout system / 6

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-034 — PARTIAL

Account for transparent PNG boundaries and the visible painted footprint.

Original reference: Part 1 / Universal decorative artwork layout system / 7

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-035 — PARTIAL

Preserve watercolor proportions, visual weight, and orientation.

Original reference: Part 1 / Universal decorative artwork layout system / 8

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-036 — PARTIAL

Prevent artwork from overlapping headings, text, controls, citations, or scientific illustrations.

Original reference: Part 1 / Universal decorative artwork layout system / 9

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-037 — PARTIAL

Prevent decorative assets from colliding with one another.

Original reference: Part 1 / Universal decorative artwork layout system / 10

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-038 — PARTIAL

Respect safe areas and screen boundaries.

Original reference: Part 1 / Universal decorative artwork layout system / 11

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-039 — PARTIAL

Recalculate placement when content expands.

Original reference: Part 1 / Universal decorative artwork layout system / 12

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-040 — PARTIAL

Recalculate placement when the keyboard appears.

Original reference: Part 1 / Universal decorative artwork layout system / 13

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-041 — PARTIAL

Recalculate placement when a popup appears.

Original reference: Part 1 / Universal decorative artwork layout system / 14

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-042 — PARTIAL

Support different iPhone sizes and Dynamic Type settings.

Original reference: Part 1 / Universal decorative artwork layout system / 15

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-043 — PARTIAL

Resize, reposition, or temporarily omit artwork when necessary.

Original reference: Part 1 / Universal decorative artwork layout system / 16

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-044 — PARTIAL

Do not indiscriminately shrink artwork to make it fit.

Original reference: Part 1 / Universal decorative artwork layout system / 17

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-045 — PARTIAL

Do not randomly redistribute, substitute, or redesign the founder’s compositions.

Original reference: Part 1 / Universal decorative artwork layout system / 18

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Existing shared component retained. Complete specification alignment and all applicable screen/state coverage still pending.
- Geometry metadata and FAQ integration await Xcode tests; other decorative call sites still require adoption.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-046 — IMPLEMENTED — VERIFICATION PENDING

Create one shared Swift system for bold, italic, and underline styling.

Original reference: Part 1 / Universal semantic text stylization / 46

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run35/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-047 — PARTIAL

Apply it across all eligible app-generated and dynamically presented text.

Original reference: Part 1 / Universal semantic text stylization / 47

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-048 — PARTIAL

Include Ask answers, fallbacks, Cycle Tracker, Fruit Basket, tutorials, popups, character dialogue, saved content, and guides.

Original reference: Part 1 / Universal semantic text stylization / 48

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-049 — PARTIAL

Remove separate feature-specific semantic formatting implementations.

Original reference: Part 1 / Universal semantic text stylization / 49

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-050 — PARTIAL

Determine emphasis from contextual meaning rather than keyword matching.

Original reference: Part 1 / Universal semantic text stylization / 50

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-051 — PARTIAL

Use bold for meaningful informational anchors.

Original reference: Part 1 / Universal semantic text stylization / 51

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-052 — PARTIAL

Include conditions, hormones, mechanisms, anatomy, nutrients, important numbers, and scientific concepts where appropriate.

Original reference: Part 1 / Universal semantic text stylization / 52

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-053 — PARTIAL

Preserve the rule that meaningful complete food names are bolded.

Original reference: Part 1 / Universal semantic text stylization / 53

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-054 — PARTIAL

Use italics for natural spoken stress.

Original reference: Part 1 / Universal semantic text stylization / 54

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-055 — PARTIAL

Use underline for symptoms and meaningful practical or qualifying clues.

Original reference: Part 1 / Universal semantic text stylization / 55

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-056 — PARTIAL

Restrict combined emphasis to situations where its meaning warrants it.

Original reference: Part 1 / Universal semantic text stylization / 56

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-057 — PARTIAL

Reserve extreme combined emphasis for the approved exceptional vocabulary and contexts.

Original reference: Part 1 / Universal semantic text stylization / 57

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-058 — PARTIAL

Avoid excessive formatting density.

Original reference: Part 1 / Universal semantic text stylization / 58

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-059 — PARTIAL

Reduce decorative emphasis in serious or safety-critical content.

Original reference: Part 1 / Universal semantic text stylization / 59

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-060 — PARTIAL

Preserve formatting during progressive rendering.

Original reference: Part 1 / Universal semantic text stylization / 60

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-061 — IMPLEMENTED — VERIFICATION PENDING

Preserve formatting when content is saved, reopened, or inserted into guides.

Original reference: Part 1 / Universal semantic text stylization / 61

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Ask/Prompt09AskModels.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift; Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run35/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-062 — PARTIAL

Prevent raw Markdown formatting markers from appearing on-screen.

Original reference: Part 1 / Universal semantic text stylization / 62

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-063 — PARTIAL

Preserve readable VoiceOver output.

Original reference: Part 1 / Universal semantic text stylization / 63

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-064 — PARTIAL

Ensure styling never causes text overflow or popup collisions.

Original reference: Part 1 / Universal semantic text stylization / 64

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift; Fruitfolio/Ask/Prompt09AskView.swift; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-065 — NOT VERIFIED

Audit unnecessary loading delays across the application.

Original reference: Part 1 / Performance and responsiveness / 65

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-066 — NOT VERIFIED

Remove avoidable UI-thread blocking.

Original reference: Part 1 / Performance and responsiveness / 66

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-067 — NOT VERIFIED

Reduce redundant calculations and processing.

Original reference: Part 1 / Performance and responsiveness / 67

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-068 — NOT VERIFIED

Ensure animations and navigation remain responsive.

Original reference: Part 1 / Performance and responsiveness / 68

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-069 — NOT VERIFIED

Optimize transitions without changing their intended appearance.

Original reference: Part 1 / Performance and responsiveness / 69

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-070 — PARTIAL

Preserve Reduce Motion behavior while eliminating unnecessary lag.

Original reference: Part 1 / Performance and responsiveness / 70

Source mappings: Fruitfolio/Hub/CutePopButtonStyle.swift; Fruitfolio/Ask/Prompt09AskViewModel.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Actual live system changes, UI recordings and audio stop on founder Mac/device; other screens require independent verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-071 — PARTIAL

Make the entire introduction transition smooth and continuous.

Original reference: Part 2 / 2A. Introduction / 71

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-072 — PARTIAL

Target an overall duration of approximately 6–8 seconds.

Original reference: Part 2 / 2A. Introduction / 72

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-073 — PARTIAL

Give each important visual stage enough time to register.

Original reference: Part 2 / 2A. Introduction / 73

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-074 — PARTIAL

Add a watercolor ripple/puddle-style logo reveal.

Original reference: Part 2 / 2A. Introduction / 74

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-075 — PARTIAL

Center that reveal precisely on the book’s existing logo position.

Original reference: Part 2 / 2A. Introduction / 75

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-076 — PARTIAL

Make the logo appear gradually rather than abruptly swapping between states.

Original reference: Part 2 / 2A. Introduction / 76

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-077 — PARTIAL

Smooth the transition from the blank book to the branded book.

Original reference: Part 2 / 2A. Introduction / 77

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-078 — PARTIAL

Smooth the slightly-open and fully-open book transitions.

Original reference: Part 2 / 2A. Introduction / 78

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-079 — PARTIAL

Smooth the right-page zoom and transition into the Hub.

Original reference: Part 2 / 2A. Introduction / 79

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-080 — PARTIAL

Eliminate visible jumps, rushed stages, and avoidable lag.

Original reference: Part 2 / 2A. Introduction / 80

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-081 — PARTIAL

Add a bottom-left skip control using the existing control_next artwork.

Original reference: Part 2 / 2A. Introduction / 81

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-082 — PARTIAL

Place the text “skip tour” underneath that control, as specified.

Original reference: Part 2 / 2A. Introduction / 82

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-083 — PARTIAL

Make the reduced-motion introduction smooth without simply accelerating the sequence.

Original reference: Part 2 / 2A. Introduction / 83

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-084 — PARTIAL

Pause the introduction when the app becomes inactive.

Original reference: Part 2 / 2A. Introduction / 84

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-085 — PARTIAL

Resume from the current logical stage rather than restarting.

Original reference: Part 2 / 2A. Introduction / 85

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-086 — PARTIAL

Prevent timers and animations from progressing invisibly in the background.

Original reference: Part 2 / 2A. Introduction / 86

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-087 — PARTIAL

Restore a completed stage cleanly when exact animation-frame restoration is unsafe.

Original reference: Part 2 / 2A. Introduction / 87

Source mappings: Fruitfolio/Introduction/Prompt04IntroConfiguration.swift; Fruitfolio/Introduction/Prompt04IntroStateMachine.swift; Fruitfolio/Introduction/Prompt04IntroView.swift; FruitfolioTests/IntroInterruptionRuntimeTests.swift; FruitfolioUITests/SimulatorSmokeEvidenceTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect complete actual intro recordings/frames on supported phones and verify the new actual Home/background/reactivation journey. No full visual smoothness or audible acceptance inferred from unit timing.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-088 — NOT VERIFIED

Optimize Hub loading and navigation responsiveness.

Original reference: Part 2 / 2B. Hub and guided tour / 88

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-089 — NOT VERIFIED

Apply the universal button-pop animation to Hub interactions.

Original reference: Part 2 / 2B. Hub and guided tour / 89

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-090 — NOT VERIFIED

Play popup-opening audio when the tour invitation appears.

Original reference: Part 2 / 2B. Hub and guided tour / 90

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-091 — NOT VERIFIED

Play popup-closing audio when the tour is dismissed or skipped.

Original reference: Part 2 / 2B. Hub and guided tour / 91

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-092 — NOT VERIFIED

Calculate tour highlights from actual button positions and dimensions.

Original reference: Part 2 / 2B. Hub and guided tour / 92

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-093 — NOT VERIFIED

Remove fixed-device assumptions from the tour spotlight geometry.

Original reference: Part 2 / 2B. Hub and guided tour / 93

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-094 — NOT VERIFIED

Keep the highlighted region precisely aligned with its corresponding button.

Original reference: Part 2 / 2B. Hub and guided tour / 94

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-095 — NOT VERIFIED

Apply semantic bold styling to important feature names in fruit-character tour dialogue.

Original reference: Part 2 / 2B. Hub and guided tour / 95

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-096 — NOT VERIFIED

Replace the limited answer presentation with a continuous vertically scrollable paper experience.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 96

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-097 — NOT VERIFIED

Keep previous questions and answers visible throughout the active Ask session.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 97

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-098 — NOT VERIFIED

Support multiple questions and long answers on the same paper.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 98

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-099 — NOT VERIFIED

Make the paper extend downward without an obvious bottom edge.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 99

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-100 — NOT VERIFIED

Prevent hard height caps and truncated answers.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 100

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-101 — NOT VERIFIED

Keep the paper horizontally centered.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 101

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-102 — NOT VERIFIED

Keep the text column centered inside the paper.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 102

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-103 — NOT VERIFIED

Calculate layout using actual runtime dimensions.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 103

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-104 — NOT VERIFIED

Prevent long answers from widening or shifting the paper.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 104

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-105 — NOT VERIFIED

Allow text to wrap and expand vertically.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 105

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-106 — NOT VERIFIED

Preserve scrolling in both directions.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 106

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-107 — NOT VERIFIED

Automatically follow new streamed text only when the user is near the bottom.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 107

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-108 — NOT VERIFIED

Do not force scrolling to the bottom while the user is reading older content.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 108

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-109 — IMPLEMENTED — VERIFICATION PENDING

Preserve text selection, citation interactions, and accessibility reading order.

Original reference: Part 3 / 3A. Continuous paper and conversation behavior / 109

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run all existing semantic/selection tests and actual selectable Ask/page-editor UI journeys with screenshots and VoiceOver.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-110 — NOT VERIFIED

Position the orange slice, orange glow, and pear relative to the opening paper.

Original reference: Part 3 / 3B. Ask fruit artwork / 110

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-111 — NOT VERIFIED

Center the orange composition.

Original reference: Part 3 / 3B. Ask fruit artwork / 111

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-112 — NOT VERIFIED

Balance the other fruit artwork evenly on either side.

Original reference: Part 3 / 3B. Ask fruit artwork / 112

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-113 — NOT VERIFIED

Maintain visually consistent spacing.

Original reference: Part 3 / 3B. Ask fruit artwork / 113

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-114 — NOT VERIFIED

Use responsive paper-relative positioning.

Original reference: Part 3 / 3B. Ask fruit artwork / 114

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-115 — NOT VERIFIED

Prevent fruit artwork from overlapping text or controls.

Original reference: Part 3 / 3B. Ask fruit artwork / 115

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-116 — NOT VERIFIED

Make the decorations scroll naturally with the paper.

Original reference: Part 3 / 3B. Ask fruit artwork / 116

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-117 — NOT VERIFIED

Do not duplicate the fruit artwork on every extended paper segment.

Original reference: Part 3 / 3B. Ask fruit artwork / 117

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-118 — NOT VERIFIED

Keep Ask conversation history only while the user remains in the active Ask session.

Original reference: Part 3 / 3C. Session-only history / 118

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-119 — NOT VERIFIED

Clear unsaved questions and answers when the user exits Ask.

Original reference: Part 3 / 3C. Session-only history / 119

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-120 — NOT VERIFIED

Clear unsaved draft text when the session ends.

Original reference: Part 3 / 3C. Session-only history / 120

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-121 — NOT VERIFIED

Open Ask with a fresh paper when the user returns.

Original reference: Part 3 / 3C. Session-only history / 121

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-122 — NOT VERIFIED

Do not silently restore old conversations after restarting the app.

Original reference: Part 3 / 3C. Session-only history / 122

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-123 — NOT VERIFIED

Do not persist transcripts through account state, analytics, or other hidden storage.

Original reference: Part 3 / 3C. Session-only history / 123

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-124 — NOT VERIFIED

Preserve only explicitly selected content saved through the Guide workflow.

Original reference: Part 3 / 3C. Session-only history / 124

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-125 — IMPLEMENTED — VERIFICATION PENDING

Retain citations and attribution for successfully saved content.

Original reference: Part 3 / 3C. Session-only history / 125

Source mappings: Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift; Fruitfolio/Saved Library/Prompt10SavedCitationResolver.swift; Fruitfolio/Saved Library/Prompt10SavedCitationsView.swift; Fruitfolio/Ask/AskSavedAttributionSnapshot.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run64/Ask_Journey/Build/xcode-ask-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run67/UnitBuild/actual-test-executions.json; Fruitfolio_Verification_Evidence/AppleRuns/Run64/Ask_Journey/Build/xcode-ask-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run67/UnitBuild/actual-test-executions.json

Remaining discrepancies:
- Run unit and actual grounded Ask save/restart journeys on founder Mac. This validates save-boundary integrity, not clinical correctness or APA accuracy independently of the unchanged evidence pipeline.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-126 — PARTIAL

Do not delete saved Guide content when the Ask session clears.

Original reference: Part 3 / 3C. Session-only history / 126

Source mappings: Fruitfolio/Ask/Prompt09AskViewModel.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryStore.swift; Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift; FruitfolioTests/AskSessionLifetimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect/verify full relevant rendered UI and accessibility states; passing underlying frame/persistence tests do not establish complete feature acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-127 — NOT VERIFIED

Confirm successful saves.

Original reference: Part 3 / 3C. Session-only history / 127

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-128 — IMPLEMENTED — VERIFICATION PENDING

Prevent canceled or failed saves from creating persistent copies.

Original reference: Part 3 / 3C. Session-only history / 128

Source mappings: Fruitfolio/Ask/AskSavedAttributionSnapshot.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run unit and actual grounded Ask save/restart journeys on founder Mac. This validates save-boundary integrity, not clinical correctness or APA accuracy independently of the unchanged evidence pipeline.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-129 — NOT VERIFIED

Audit the complete local retrieval and generation pipeline.

Original reference: Part 3 / 3D. Ask AI performance / 129

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-130 — NOT VERIFIED

Identify repeated retrieval and redundant model operations.

Original reference: Part 3 / 3D. Ask AI performance / 130

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-131 — NOT VERIFIED

Eliminate unnecessary sequential processing.

Original reference: Part 3 / 3D. Ask AI performance / 131

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-132 — NOT VERIFIED

Run independent operations concurrently where safe.

Original reference: Part 3 / 3D. Ask AI performance / 132

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-133 — NOT VERIFIED

Cache appropriate reusable results.

Original reference: Part 3 / 3D. Ask AI performance / 133

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-134 — NOT VERIFIED

Begin displaying validated content as soon as practical.

Original reference: Part 3 / 3D. Ask AI performance / 134

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-135 — NOT VERIFIED

Reduce delays for typed and suggested questions.

Original reference: Part 3 / 3D. Ask AI performance / 135

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-136 — PARTIAL

Preserve research retrieval, claim/evidence mapping, medical safety, and citation validation.

Original reference: Part 3 / 3D. Ask AI performance / 136

Source mappings: Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run full grounding suites and controlled offline native FruitfolioAI verification on founder Mac. Structural identities do not independently verify clinical accuracy.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-137 — IMPLEMENTED — VERIFICATION PENDING

Preserve Canonical Voice and semantic styling during performance optimization.

Original reference: Part 3 / 3D. Ask AI performance / 137

Source mappings: Fruitfolio/Core/Voice/FruitfolioCanonicalVoice.swift; Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift; Fruitfolio/Core/ProductionPhases/Prompt32To55ProductionSystems.swift; FruitfolioTests/CanonicalVoiceAndKaomojiTests.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/CANONICAL_VOICE_AND_KAOMOJI.md; Delivery/CANONICAL_VOICE_AND_KAOMOJI.md

Remaining discrepancies:
- New actual Apple build/unit/native Ask/UI tests pending. Full founder Guide-based long-form voice, emotional interpretation and every-feature adoption remain incomplete.
- Run all existing semantic/selection tests and actual selectable Ask/page-editor UI journeys with screenshots and VoiceOver.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-138 — NOT VERIFIED

Use typing ASMR during answer presentation unless disabled by the user.

Original reference: Part 3 / 3E. Answer presentation / 138

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-139 — NOT VERIFIED

Ensure answers remain fully contained inside the paper.

Original reference: Part 3 / 3E. Answer presentation / 139

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-140 — NOT VERIFIED

Keep answer text horizontally centered within its readable area.

Original reference: Part 3 / 3E. Answer presentation / 140

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-141 — IMPLEMENTED — VERIFICATION PENDING

Preserve selectable text and functional citation controls.

Original reference: Part 3 / 3E. Answer presentation / 141

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift; Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run all existing semantic/selection tests and actual selectable Ask/page-editor UI journeys with screenshots and VoiceOver.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-142 — IMPLEMENTED — VERIFICATION PENDING

Default to no educational illustration.

Original reference: Part 3 / 3E. Answer presentation / 142

Source mappings: Fruitfolio/Ask/Prompt09EducationalAssetRouter.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Actual per-answer material educational benefit and full visual appropriateness still need curated/runtimed verification; two anchors alone are not a complete scientific illustration review.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-143 — PARTIAL

Display scientific artwork only when it materially improves understanding.

Original reference: Part 3 / 3E. Answer presentation / 143

Source mappings: Fruitfolio/Ask/Prompt09EducationalAssetRouter.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Actual per-answer material educational benefit and full visual appropriateness still need curated/runtimed verification; two anchors alone are not a complete scientific illustration review.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-144 — PARTIAL

Do not select artwork merely because an asset matches a keyword.

Original reference: Part 3 / 3E. Answer presentation / 144

Source mappings: Fruitfolio/Ask/Prompt09EducationalAssetRouter.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Actual per-answer material educational benefit and full visual appropriateness still need curated/runtimed verification; two anchors alone are not a complete scientific illustration review.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-145 — IMPLEMENTED — VERIFICATION PENDING

Generally limit an ordinary answer to one major educational illustration when genuinely appropriate.

Original reference: Part 3 / 3E. Answer presentation / 145

Source mappings: Fruitfolio/Ask/Prompt09EducationalAssetRouter.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Actual per-answer material educational benefit and full visual appropriateness still need curated/runtimed verification; two anchors alone are not a complete scientific illustration review.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-146 — NOT VERIFIED

Reserve sequential scientific artwork for explicitly opened illustrated experiences.

Original reference: Part 3 / 3E. Answer presentation / 146

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-147 — NOT VERIFIED

Do not create anatomy collages or use educational illustrations as decoration.

Original reference: Part 3 / 3E. Answer presentation / 147

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-148 — NOT VERIFIED

Apply FruitsofLife.xo’s canonical writing style to normal Ask responses.

Original reference: Part 3 / 3F. Canonical AI writing / 148

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-149 — NOT VERIFIED

Apply the same style to retrieval-only fallbacks.

Original reference: Part 3 / 3F. Canonical AI writing / 149

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-150 — NOT VERIFIED

Apply it to model-failure and other substantive fallback responses.

Original reference: Part 3 / 3F. Canonical AI writing / 150

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-151 — PARTIAL

Remove any separate simplified fallback voice.

Original reference: Part 3 / 3F. Canonical AI writing / 151

Source mappings: Fruitfolio/Core/Voice/FruitfolioCanonicalVoice.swift; Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift; Fruitfolio/Core/ProductionPhases/Prompt32To55ProductionSystems.swift; FruitfolioTests/CanonicalVoiceAndKaomojiTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/CANONICAL_VOICE_AND_KAOMOJI.md; Delivery/CANONICAL_VOICE_AND_KAOMOJI.md

Remaining discrepancies:
- New actual Apple build/unit/native Ask/UI tests pending. Full founder Guide-based long-form voice, emotional interpretation and every-feature adoption remain incomplete.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-152 — NOT VERIFIED

Make fallback responses answer the user’s question before presenting supporting research.

Original reference: Part 3 / 3F. Canonical AI writing / 152

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-153 — PARTIAL

Preserve the human-bridge-to-evidence response structure.

Original reference: Part 3 / 3F. Canonical AI writing / 153

Source mappings: Fruitfolio/Core/Voice/FruitfolioCanonicalVoice.swift; Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift; Fruitfolio/Core/ProductionPhases/Prompt32To55ProductionSystems.swift; FruitfolioTests/CanonicalVoiceAndKaomojiTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/CANONICAL_VOICE_AND_KAOMOJI.md; Delivery/CANONICAL_VOICE_AND_KAOMOJI.md

Remaining discrepancies:
- New actual Apple build/unit/native Ask/UI tests pending. Full founder Guide-based long-form voice, emotional interpretation and every-feature adoption remain incomplete.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-154 — NOT VERIFIED

Use ☆ for main points and - for supporting points where appropriate.

Original reference: Part 3 / 3F. Canonical AI writing / 154

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-155 — NOT VERIFIED

Follow lowercase and approved capitalization rules.

Original reference: Part 3 / 3F. Canonical AI writing / 155

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-156 — NOT VERIFIED

Apply approved punctuation, contractions, rhythm, and warmth.

Original reference: Part 3 / 3F. Canonical AI writing / 156

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-157 — PARTIAL

Use kaomojis sparingly according to the canonical frequency rules.

Original reference: Part 3 / 3F. Canonical AI writing / 157

Source mappings: Fruitfolio/Core/Voice/FruitfolioCanonicalVoice.swift; Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift; Fruitfolio/Core/ProductionPhases/Prompt32To55ProductionSystems.swift; FruitfolioTests/CanonicalVoiceAndKaomojiTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/CANONICAL_VOICE_AND_KAOMOJI.md; Delivery/CANONICAL_VOICE_AND_KAOMOJI.md

Remaining discrepancies:
- New actual Apple build/unit/native Ask/UI tests pending. Full founder Guide-based long-form voice, emotional interpretation and every-feature adoption remain incomplete.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-158 — PARTIAL

Suppress kaomojis in serious medical, safety-critical, abuse/consent, and laboratory-interpretation contexts.

Original reference: Part 3 / 3F. Canonical AI writing / 158

Source mappings: Fruitfolio/Core/Voice/FruitfolioCanonicalVoice.swift; Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift; Fruitfolio/Core/ProductionPhases/Prompt32To55ProductionSystems.swift; FruitfolioTests/CanonicalVoiceAndKaomojiTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/CANONICAL_VOICE_AND_KAOMOJI.md; Delivery/CANONICAL_VOICE_AND_KAOMOJI.md

Remaining discrepancies:
- New actual Apple build/unit/native Ask/UI tests pending. Full founder Guide-based long-form voice, emotional interpretation and every-feature adoption remain incomplete.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-159 — NOT VERIFIED

Adapt tone to reasonably evident conversational cues without diagnosing the user’s emotional state.

Original reference: Part 3 / 3F. Canonical AI writing / 159

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-160 — NOT VERIFIED

Apply the universal semantic styling system to every substantive answer pathway.

Original reference: Part 3 / 3F. Canonical AI writing / 160

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-161 — NOT VERIFIED

Ensure source displays use verified source information.

Original reference: Part 3 / 3G. Research and source handling / 161

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-162 — IMPLEMENTED — VERIFICATION PENDING

Preserve source titles, publication details, and citation identifiers.

Original reference: Part 3 / 3G. Research and source handling / 162

Source mappings: Fruitfolio/Ask/AskSavedAttributionSnapshot.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run unit and actual grounded Ask save/restart journeys on founder Mac. This validates save-boundary integrity, not clinical correctness or APA accuracy independently of the unchanged evidence pipeline.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-163 — NOT VERIFIED

Apply the document’s approved-source access rules without weakening the local research architecture.

Original reference: Part 3 / 3G. Research and source handling / 163

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-164 — NOT VERIFIED

Preserve distinctions between supported, partially supported, and unsupported questions.

Original reference: Part 3 / 3G. Research and source handling / 164

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-165 — IMPLEMENTED — VERIFICATION PENDING

Do not use unsupported-topic fallbacks before the available research architecture has been appropriately searched.

Original reference: Part 3 / 3G. Research and source handling / 165

Source mappings: Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run the new and full grounding suites on founder Mac; verify actual grounded questions, citations and fallback behavior. UI localization does not establish translated research support.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-166 — NOT VERIFIED

Correct the help overlay to provide the requested actual help popup.

Original reference: Part 3 / 3H. Ask interaction changes / 166

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-167 — IMPLEMENTED — VERIFICATION PENDING

Apply the updated popup system to Ask help and save interactions.

Original reference: Part 3 / 3H. Ask interaction changes / 167

Source mappings: Fruitfolio/Ask/AskSavedAttributionSnapshot.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run unit and actual grounded Ask save/restart journeys on founder Mac. This validates save-boundary integrity, not clinical correctness or APA accuracy independently of the unchanged evidence pipeline.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-168 — NOT VERIFIED

Integrate the specified save-related visual treatment.

Original reference: Part 3 / 3H. Ask interaction changes / 168

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-169 — NOT VERIFIED

Preserve correct transitions into the selected save destination.

Original reference: Part 3 / 3H. Ask interaction changes / 169

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-170 — NOT VERIFIED

Change the empty-state wording to the specified “nothing here yet!” version.

Original reference: Part 4 / 4A. My Encyclopedias / 1

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-171 — NOT VERIFIED

Make the populated decorative bookshelf identical to the empty-state decorative bookshelf.

Original reference: Part 4 / 4A. My Encyclopedias / 2

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-172 — NOT VERIFIED

Remove duplicate bookshelf artwork.

Original reference: Part 4 / 4A. My Encyclopedias / 3

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-173 — NOT VERIFIED

Do not add duplicate books, flowers, labels, bookmarks, plants, or other decorations.

Original reference: Part 4 / 4A. My Encyclopedias / 4

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-174 — NOT VERIFIED

Keep actual saved encyclopedias in their separate interactive collection.

Original reference: Part 4 / 4A. My Encyclopedias / 5

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-175 — NOT VERIFIED

Improve accessibility of sorting controls.

Original reference: Part 4 / 4A. My Encyclopedias / 6

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-176 — NOT VERIFIED

Add appropriate character limits to encyclopedia titles.

Original reference: Part 4 / 4A. My Encyclopedias / 7

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-177 — NOT VERIFIED

Add appropriate character limits to descriptions.

Original reference: Part 4 / 4A. My Encyclopedias / 8

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-178 — NOT VERIFIED

Validate titles and descriptions against the specified non-explicit-content rules.

Original reference: Part 4 / 4A. My Encyclopedias / 9

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-179 — NOT VERIFIED

Do not incorrectly reject legitimate sexual-health terminology.

Original reference: Part 4 / 4A. My Encyclopedias / 10

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-180 — NOT VERIFIED

Improve the positioning of book titles and descriptions.

Original reference: Part 4 / 4A. My Encyclopedias / 11

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-181 — NOT VERIFIED

Prevent text from bunching up against book artwork.

Original reference: Part 4 / 4A. My Encyclopedias / 12

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-182 — IMPLEMENTED — VERIFICATION PENDING

Replace the staged artwork-swap animation with a continuous coded book animation.

Original reference: Part 4 / 4B. Book-opening animation / 182

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-183 — PARTIAL

Begin with the user’s actual selected book spine.

Original reference: Part 4 / 4B. Book-opening animation / 183

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Exact reference appearance/initial spine continuity, live motion and saved reading-page composition require verification; full content-container alignment remains partial.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-184 — IMPLEMENTED — VERIFICATION PENDING

Preserve the selected book color throughout the sequence.

Original reference: Part 4 / 4B. Book-opening animation / 184

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-185 — IMPLEMENTED — VERIFICATION PENDING

Move the same book forward from the bookshelf.

Original reference: Part 4 / 4B. Book-opening animation / 185

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-186 — IMPLEMENTED — VERIFICATION PENDING

Center it in front of the user.

Original reference: Part 4 / 4B. Book-opening animation / 186

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-187 — IMPLEMENTED — VERIFICATION PENDING

Animate the book opening continuously.

Original reference: Part 4 / 4B. Book-opening animation / 187

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-188 — IMPLEMENTED — VERIFICATION PENDING

Move from closed to partially open to fully open without discrete image swaps.

Original reference: Part 4 / 4B. Book-opening animation / 188

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-189 — IMPLEMENTED — VERIFICATION PENDING

Keep the complete open book visible.

Original reference: Part 4 / 4B. Book-opening animation / 189

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-190 — IMPLEMENTED — VERIFICATION PENDING

Do not zoom into the right-hand page.

Original reference: Part 4 / 4B. Book-opening animation / 190

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-191 — IMPLEMENTED — VERIFICATION PENDING

Smoothly reposition and scale the entire book into the inside-book layout.

Original reference: Part 4 / 4B. Book-opening animation / 191

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-192 — PARTIAL

Render saved content inside that same book.

Original reference: Part 4 / 4B. Book-opening animation / 192

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Exact reference appearance/initial spine continuity, live motion and saved reading-page composition require verification; full content-container alignment remains partial.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-193 — PARTIAL

Prevent book duplication, disappearance, jumps, and color resets.

Original reference: Part 4 / 4B. Book-opening animation / 193

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Exact reference appearance/initial spine continuity, live motion and saved reading-page composition require verification; full content-container alignment remains partial.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-194 — IMPLEMENTED — VERIFICATION PENDING

Remove the smaller library_book_open artwork from inside the book.

Original reference: Part 4 / 4B. Book-opening animation / 194

Source mappings: Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/UserPages/Visual/UserPages/320FD5FD-F8C0-49B5-B068-C08DF380EC17.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/UserPages/Visual/UserPages/320FD5FD-F8C0-49B5-B068-C08DF380EC17.png

Remaining discrepancies:
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-195 — IMPLEMENTED — VERIFICATION PENDING

Center the final coded open book near the top of the screen.

Original reference: Part 4 / 4B. Book-opening animation / 195

Source mappings: Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-196 — IMPLEMENTED — VERIFICATION PENDING

Remove the extra bottom bookmark and flower decorations.

Original reference: Part 4 / 4B. Book-opening animation / 196

Source mappings: Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10CodedBookArtwork.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift

Source-sprint records: Delivery/FiveHour_Phase1_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/UserPages/Visual/UserPages/320FD5FD-F8C0-49B5-B068-C08DF380EC17.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/UserPages/Visual/UserPages/320FD5FD-F8C0-49B5-B068-C08DF380EC17.png

Remaining discrepancies:
- Execute the integrated tests and visually compare the actual animation and final layout; source implementation alone is not PASS.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-197 — PARTIAL

Allow users to add their own notes.

Original reference: Part 4 / 4C. Encyclopedia editing / 197

Source mappings: Fruitfolio/Saved Library/Prompt10UserPageEditor.swift; Fruitfolio/Saved Library/Prompt10ChapterManagementView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10LocalMediaStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Actual creation/relaunch/edit/discard/delete UI journey remains in repair; photo-picker import, cancellation and image-sharing flows need actual simulator/device verification. Physical file protection is NOT VERIFIED.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-198 — PARTIAL

Allow users to import their own images from their device or photo library.

Original reference: Part 4 / 4C. Encyclopedia editing / 198

Source mappings: Fruitfolio/Saved Library/Prompt10UserPageEditor.swift; Fruitfolio/Saved Library/Prompt10ChapterManagementView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10LocalMediaStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Actual creation/relaunch/edit/discard/delete UI journey remains in repair; photo-picker import, cancellation and image-sharing flows need actual simulator/device verification. Physical file protection is NOT VERIFIED.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-199 — PARTIAL

Allow users to add independently researched material.

Original reference: Part 4 / 4C. Encyclopedia editing / 199

Source mappings: Fruitfolio/Saved Library/Prompt10UserPageEditor.swift; Fruitfolio/Saved Library/Prompt10ChapterManagementView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10LocalMediaStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Actual creation/relaunch/edit/discard/delete UI journey remains in repair; photo-picker import, cancellation and image-sharing flows need actual simulator/device verification. Physical file protection is NOT VERIFIED.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-200 — PARTIAL

Let users choose the chapter or location where material belongs.

Original reference: Part 4 / 4C. Encyclopedia editing / 200

Source mappings: Fruitfolio/Saved Library/Prompt10UserPageEditor.swift; Fruitfolio/Saved Library/Prompt10ChapterManagementView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10LocalMediaStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Actual creation/relaunch/edit/discard/delete UI journey remains in repair; photo-picker import, cancellation and image-sharing flows need actual simulator/device verification. Physical file protection is NOT VERIFIED.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-201 — PARTIAL

Allow user-added content to be edited.

Original reference: Part 4 / 4C. Encyclopedia editing / 201

Source mappings: Fruitfolio/Saved Library/Prompt10UserPageEditor.swift; Fruitfolio/Saved Library/Prompt10ChapterManagementView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10LocalMediaStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Actual creation/relaunch/edit/discard/delete UI journey remains in repair; photo-picker import, cancellation and image-sharing flows need actual simulator/device verification. Physical file protection is NOT VERIFIED.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-202 — PARTIAL

Allow imported images to be removed or replaced.

Original reference: Part 4 / 4C. Encyclopedia editing / 202

Source mappings: Fruitfolio/Saved Library/Prompt10UserPageEditor.swift; Fruitfolio/Saved Library/Prompt10ChapterManagementView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10LocalMediaStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Actual creation/relaunch/edit/discard/delete UI journey remains in repair; photo-picker import, cancellation and image-sharing flows need actual simulator/device verification. Physical file protection is NOT VERIFIED.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-203 — PARTIAL

Provide save and discard behavior.

Original reference: Part 4 / 4C. Encyclopedia editing / 203

Source mappings: Fruitfolio/Saved Library/Prompt10UserPageEditor.swift; Fruitfolio/Saved Library/Prompt10ChapterManagementView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10LocalMediaStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Actual creation/relaunch/edit/discard/delete UI journey remains in repair; photo-picker import, cancellation and image-sharing flows need actual simulator/device verification. Physical file protection is NOT VERIFIED.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-204 — PARTIAL

Protect unsaved edits.

Original reference: Part 4 / 4C. Encyclopedia editing / 204

Source mappings: Fruitfolio/Saved Library/Prompt10UserPageEditor.swift; Fruitfolio/Saved Library/Prompt10ChapterManagementView.swift; Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift; Fruitfolio/Saved Library/Prompt10LocalMediaStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Actual creation/relaunch/edit/discard/delete UI journey remains in repair; photo-picker import, cancellation and image-sharing flows need actual simulator/device verification. Physical file protection is NOT VERIFIED.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-205 — NOT VERIFIED

Do not generate images on the user’s behalf.

Original reference: Part 4 / 4C. Encyclopedia editing / 205

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-206 — NOT VERIFIED

Create one shared source of truth for guides.

Original reference: Part 4 / 4D. Shared Guide data / 206

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-207 — NOT VERIFIED

Synchronize guides across Ask, My Encyclopedias, and Build Your Own Guide.

Original reference: Part 4 / 4D. Shared Guide data / 207

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-208 — NOT VERIFIED

Ensure creation, renaming, editing, recoloring, and deletion propagate everywhere.

Original reference: Part 4 / 4D. Shared Guide data / 208

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-209 — NOT VERIFIED

Preserve guide title, cover style, contents, ordering, and edits.

Original reference: Part 4 / 4D. Shared Guide data / 209

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-210 — NOT VERIFIED

Prevent duplicate feature-specific guide records.

Original reference: Part 4 / 4D. Shared Guide data / 210

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-211 — NOT VERIFIED

Apply the updated empty-shelf wording.

Original reference: Part 4 / 4E. Build Your Own Guide / 211

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-212 — NOT VERIFIED

Remove the decorative guide folder once a guide is selected.

Original reference: Part 4 / 4E. Build Your Own Guide / 212

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-213 — NOT VERIFIED

Show only the selected guide spine in its chosen color/style during editing.

Original reference: Part 4 / 4E. Build Your Own Guide / 213

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-214 — NOT VERIFIED

Keep the folder artwork in the initial Guide Builder state only.

Original reference: Part 4 / 4E. Build Your Own Guide / 214

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-215 — NOT VERIFIED

Apply the specified updated empty-section and empty-guide wording.

Original reference: Part 4 / 4E. Build Your Own Guide / 215

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-216 — NOT VERIFIED

Ensure the empty-section text includes the requested exclamation point.

Original reference: Part 4 / 4E. Build Your Own Guide / 216

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-217 — NOT VERIFIED

Apply universal popup layout rules to guide creation and editing.

Original reference: Part 4 / 4E. Build Your Own Guide / 217

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-218 — NOT VERIFIED

Replace the save confirmation with the specified Strawberry presentation.

Original reference: Part 4 / 4E. Build Your Own Guide / 218

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-219 — NOT VERIFIED

Show Strawberry with “saved!” directly underneath.

Original reference: Part 4 / 4E. Build Your Own Guide / 219

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-220 — NOT VERIFIED

Use the existing large control-card popup artwork.

Original reference: Part 4 / 4E. Build Your Own Guide / 220

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-221 — NOT VERIFIED

Adjust that card’s scale to fit the intended composition.

Original reference: Part 4 / 4E. Build Your Own Guide / 221

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-222 — IMPLEMENTED — VERIFICATION PENDING

Add or verify separately adjustable volume controls for music, rain, sound effects, and typing.

Original reference: Part 5 / 5A. Settings and audio / 222

Source mappings: Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioUITests/SettingsVolumeUITests.swift; Fruitfolio/Core/Assets/AudioManager.swift; FruitfolioTests/AudioLifecycleRuntimeTests.swift

Source-sprint records: Delivery/FiveHour_Phase2_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run39/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run39/SettingsVolumes/Visual/SettingsVolumes/24B1D40E-CE76-4A13-A562-01253248D5DD.png; Fruitfolio_Verification_Evidence/AppleRuns/Run41/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run41/SettingsVolumes/visual-review.md; Fruitfolio_Verification_Evidence/AppleRuns/Run50/Volumes/Build/xcode-settings-volumes-ui-test.log; Delivery/RUN50_VOLUME_NAVIGATION_DIAGNOSTIC.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Volumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Volumes/Visual/SettingsVolumes/manifest.json; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Fruitfolio_Verification_Evidence/AppleRuns/Run39/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run39/SettingsVolumes/Visual/SettingsVolumes/24B1D40E-CE76-4A13-A562-01253248D5DD.png; Fruitfolio_Verification_Evidence/AppleRuns/Run41/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run41/SettingsVolumes/visual-review.md; Fruitfolio_Verification_Evidence/AppleRuns/Run50/Volumes/Build/xcode-settings-volumes-ui-test.log; Delivery/RUN50_VOLUME_NAVIGATION_DIAGNOSTIC.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Volumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Volumes/Visual/SettingsVolumes/manifest.json; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json

Remaining discrepancies:
- Founder Mac execution, real interruptions and audible output/quality still require verification; these source changes do not constitute complete requirement acceptance.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-223 — IMPLEMENTED — VERIFICATION PENDING

Ensure each control updates the actual audio system.

Original reference: Part 5 / 5A. Settings and audio / 223

Source mappings: Fruitfolio/Core/Assets/AudioManager.swift; FruitfolioTests/AudioLifecycleRuntimeTests.swift

Source-sprint records: Delivery/FiveHour_Phase2_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Founder Mac execution, real interruptions and audible output/quality still require verification; these source changes do not constitute complete requirement acceptance.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-224 — IMPLEMENTED — VERIFICATION PENDING

Provide a functioning global mute.

Original reference: Part 5 / 5A. Settings and audio / 224

Source mappings: Fruitfolio/Core/Assets/AudioManager.swift; Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-225 — IMPLEMENTED — VERIFICATION PENDING

Provide a functioning background-music toggle.

Original reference: Part 5 / 5A. Settings and audio / 225

Source mappings: Fruitfolio/Core/Assets/AudioManager.swift; Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-226 — IMPLEMENTED — VERIFICATION PENDING

Prevent muted or disabled audio from continuing to play.

Original reference: Part 5 / 5A. Settings and audio / 226

Source mappings: Fruitfolio/Core/Assets/AudioManager.swift; FruitfolioTests/AudioLifecycleRuntimeTests.swift

Source-sprint records: Delivery/FiveHour_Phase2_RequirementChanges.json; Delivery/FiveHour_Phase7_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/actual-runtime-attachments-index.json; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/actual-runtime-attachments-index.json; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Founder Mac execution, real interruptions and audible output/quality still require verification; these source changes do not constitute complete requirement acceptance.
- Execute on Mac; real device interruptions, route changes and listening quality remain unverified.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-227 — IMPLEMENTED — VERIFICATION PENDING

Ensure audio preferences persist appropriately.

Original reference: Part 5 / 5A. Settings and audio / 227

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/Assets/AudioManager.swift; FruitfolioTests/AudioLifecycleRuntimeTests.swift

Source-sprint records: Delivery/FiveHour_Phase2_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run41/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run41/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log

Remaining discrepancies:
- Founder Mac execution, real interruptions and audible output/quality still require verification; these source changes do not constitute complete requirement acceptance.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-228 — NOT VERIFIED

Apply the shared control artwork and button interactions.

Original reference: Part 5 / 5A. Settings and audio / 228

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-229 — PARTIAL

Allow users to create and edit their username alongside their email.

Original reference: Part 5 / 5B. Account / 229

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/FruitfolioUsernameStoreTests.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Public server uniqueness/moderation needs configured backend. Existing deterministic moderation is not comprehensive multilingual moderation. The app cannot establish a user’s actual legal name without a founder-approved privacy-preserving verification policy; no unsupported identity inference or legal-name collection was added.
- Local strict validation/shared persistence exists. Production identity reservation, comprehensive moderation and privacy-preserving real-name enforcement remain incomplete; no legal-name collection or fake backend was added.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-230 — IMPLEMENTED — VERIFICATION PENDING

Use the same username for Account and Fruit Basket.

Original reference: Part 5 / 5B. Account / 230

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift; Fruitfolio/Privacy Settings/Prompt12AccountView.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioUITests/UsernameSynchronizationUITests.swift; FruitfolioTests/FruitfolioUsernameStoreTests.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/USERNAME_EDITING_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UsernameJourney/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UsernameJourney/Build/xcode-username-journey-ui-test.log; Delivery/RUN46_RUNTIME_DIAGNOSTIC_REPAIRS.md; Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/USERNAME_EDITING_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UsernameJourney/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UsernameJourney/Build/xcode-username-journey-ui-test.log; Delivery/RUN46_RUNTIME_DIAGNOSTIC_REPAIRS.md; Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log

Remaining discrepancies:
- Public server uniqueness/moderation needs configured backend. Existing deterministic moderation is not comprehensive multilingual moderation. The app cannot establish a user’s actual legal name without a founder-approved privacy-preserving verification policy; no unsupported identity inference or legal-name collection was added.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-231 — IMPLEMENTED — VERIFICATION PENDING

Synchronize username changes automatically.

Original reference: Part 5 / 5B. Account / 231

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift; Fruitfolio/Privacy Settings/Prompt12AccountView.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioUITests/UsernameSynchronizationUITests.swift; FruitfolioTests/FruitfolioUsernameStoreTests.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/USERNAME_EDITING_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UsernameJourney/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UsernameJourney/Build/xcode-username-journey-ui-test.log; Delivery/RUN46_RUNTIME_DIAGNOSTIC_REPAIRS.md; Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/USERNAME_EDITING_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UsernameJourney/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UsernameJourney/Build/xcode-username-journey-ui-test.log; Delivery/RUN46_RUNTIME_DIAGNOSTIC_REPAIRS.md; Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log

Remaining discrepancies:
- Public server uniqueness/moderation needs configured backend. Existing deterministic moderation is not comprehensive multilingual moderation. The app cannot establish a user’s actual legal name without a founder-approved privacy-preserving verification policy; no unsupported identity inference or legal-name collection was added.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-232 — PARTIAL

Apply appropriate username character limits and moderation.

Original reference: Part 5 / 5B. Account / 232

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/FruitfolioUsernameStoreTests.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Public server uniqueness/moderation needs configured backend. Existing deterministic moderation is not comprehensive multilingual moderation. The app cannot establish a user’s actual legal name without a founder-approved privacy-preserving verification policy; no unsupported identity inference or legal-name collection was added.
- Local strict validation/shared persistence exists. Production identity reservation, comprehensive moderation and privacy-preserving real-name enforcement remain incomplete; no legal-name collection or fake backend was added.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-233 — PARTIAL

Reject explicit or otherwise prohibited usernames.

Original reference: Part 5 / 5B. Account / 233

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/FruitfolioUsernameStoreTests.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Public server uniqueness/moderation needs configured backend. Existing deterministic moderation is not comprehensive multilingual moderation. The app cannot establish a user’s actual legal name without a founder-approved privacy-preserving verification policy; no unsupported identity inference or legal-name collection was added.
- Local strict validation/shared persistence exists. Production identity reservation, comprehensive moderation and privacy-preserving real-name enforcement remain incomplete; no legal-name collection or fake backend was added.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-234 — PARTIAL

Enforce the requirement against using real names for leaderboard identities.

Original reference: Part 5 / 5B. Account / 234

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/FruitfolioUsernameStoreTests.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Public server uniqueness/moderation needs configured backend. Existing deterministic moderation is not comprehensive multilingual moderation. The app cannot establish a user’s actual legal name without a founder-approved privacy-preserving verification policy; no unsupported identity inference or legal-name collection was added.
- Local strict validation/shared persistence exists. Production identity reservation, comprehensive moderation and privacy-preserving real-name enforcement remain incomplete; no legal-name collection or fake backend was added.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-235 — NOT VERIFIED

Add Cycle Tracker → My Context → Hormone Information.

Original reference: Part 5 / 5C. Hormone Information — new section / 1

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-236 — NOT VERIFIED

Keep the entry visible even when no measurements exist.

Original reference: Part 5 / 5C. Hormone Information — new section / 2

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-237 — NOT VERIFIED

Make hormone tracking optional.

Original reference: Part 5 / 5C. Hormone Information — new section / 3

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-238 — NOT VERIFIED

Add the specified empty-state text.

Original reference: Part 5 / 5C. Hormone Information — new section / 4

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-239 — IMPLEMENTED — VERIFICATION PENDING

Add an Add Measurement button.

Original reference: Part 5 / 5C. Hormone Information — new section / 5

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurement.swift; FruitfolioTests/HormoneMeasurementTests.swift; FruitfolioUITests/HormoneMeasurementUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-240 — NOT VERIFIED

Support estradiol, progesterone, LH, FSH, testosterone, prolactin, and AMH.

Original reference: Part 5 / 5C. Hormone Information — new section / 6

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-241 — NOT VERIFIED

Include a controlled Other Hormone option.

Original reference: Part 5 / 5C. Hormone Information — new section / 7

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-242 — NOT VERIFIED

Add required fields for hormone, numerical result, unit, and test date.

Original reference: Part 5 / 5C. Hormone Information — new section / 8

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-243 — NOT VERIFIED

Add optional fields for sample type, cycle day, laboratory reference range, and notes.

Original reference: Part 5 / 5C. Hormone Information — new section / 9

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-244 — PASS

Validate numerical values and required fields.

Original reference: Part 5 / 5C. Hormone Information — new section / 10

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurement.swift; FruitfolioTests/HormoneMeasurementTests.swift; FruitfolioUITests/HormoneMeasurementUITests.swift

Source-sprint records: 

Current verification: PASS — scoped unchanged implementation with recorded historical execution

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/FiveHourSprint/Phase8Integration/UnchangedHormoneValidationEvidence.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json

Remaining discrepancies:

## FF1B-245 — PASS

Permit decimal values.

Original reference: Part 5 / 5C. Hormone Information — new section / 11

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurement.swift; FruitfolioTests/HormoneMeasurementTests.swift; FruitfolioUITests/HormoneMeasurementUITests.swift

Source-sprint records: 

Current verification: PASS — scoped unchanged implementation with recorded historical execution

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/FiveHourSprint/Phase8Integration/UnchangedHormoneValidationEvidence.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json

Remaining discrepancies:

## FF1B-246 — PASS

Preserve the exact entered units.

Original reference: Part 5 / 5C. Hormone Information — new section / 12

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurement.swift; FruitfolioTests/HormoneMeasurementTests.swift; FruitfolioUITests/HormoneMeasurementUITests.swift

Source-sprint records: 

Current verification: PASS — scoped unchanged implementation with recorded historical execution

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/FiveHourSprint/Phase8Integration/UnchangedHormoneValidationEvidence.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json

Remaining discrepancies:

## FF1B-247 — NOT VERIFIED

Do not silently convert units or infer missing information.

Original reference: Part 5 / 5C. Hormone Information — new section / 13

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-248 — IMPLEMENTED — VERIFICATION PENDING

Support cancellation and unsaved-change protection.

Original reference: Part 5 / 5C. Hormone Information — new section / 14

Source mappings: Fruitfolio/Hormone Information/HormoneInformationView.swift; FruitfolioUITests/HormoneMeasurementUITests.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Actual simulator execution, strict audits and chart/accessibility acceptance remain pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-249 — IMPLEMENTED — VERIFICATION PENDING

Store measurements locally.

Original reference: Part 5 / 5C. Hormone Information — new section / 15

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurement.swift; FruitfolioTests/HormoneMeasurementTests.swift; FruitfolioUITests/HormoneMeasurementUITests.swift; Fruitfolio/Hormone Information/HormoneMeasurementStore.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json

Remaining discrepancies:
- New safety path and unaffected save/edit/delete/export journeys require Mac regression verification.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-250 — IMPLEMENTED — VERIFICATION PENDING

Preserve measurements across app restarts.

Original reference: Part 5 / 5C. Hormone Information — new section / 16

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurement.swift; FruitfolioTests/HormoneMeasurementTests.swift; FruitfolioUITests/HormoneMeasurementUITests.swift; Fruitfolio/Hormone Information/HormoneMeasurementStore.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json

Remaining discrepancies:
- New safety path and unaffected save/edit/delete/export journeys require Mac regression verification.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-251 — IMPLEMENTED — VERIFICATION PENDING

Allow viewing, filtering, sorting, editing, and deleting records.

Original reference: Part 5 / 5C. Hormone Information — new section / 17

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurementStore.swift; FruitfolioTests/HormoneMeasurementTests.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- New safety path and unaffected save/edit/delete/export journeys require Mac regression verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-252 — NOT VERIFIED

Confirm deletion.

Original reference: Part 5 / 5C. Hormone Information — new section / 18

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurement.swift; FruitfolioTests/HormoneMeasurementTests.swift; FruitfolioUITests/HormoneMeasurementUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md

Remaining discrepancies:
- Retrieve actual current-source deletion guard and complete lifecycle UI results; do not infer them from older native-dialog acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-253 — IMPLEMENTED — VERIFICATION PENDING

Support repeated measurements over time.

Original reference: Part 5 / 5C. Hormone Information — new section / 19

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurementStore.swift; Fruitfolio/Hormone Information/HormoneMeasurement.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-254 — NOT VERIFIED

Restrict measurement graphs to actual recorded values.

Original reference: Part 5 / 5C. Hormone Information — new section / 20

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurementHistoryChart.swift; FruitfolioTests/HormoneMeasurementHistoryTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/HORMONE_MEASUREMENT_DISPLAY_DECISION.md; Delivery/HORMONE_MEASUREMENT_DISPLAY_DECISION.md

Remaining discrepancies:
- New chart source awaits actual Run46 compilation, unit execution, simulator visual/accessibility review.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-255 — NOT VERIFIED

Never invent or interpolate missing laboratory results.

Original reference: Part 5 / 5C. Hormone Information — new section / 21

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurementHistoryChart.swift; FruitfolioTests/HormoneMeasurementHistoryTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/HORMONE_MEASUREMENT_DISPLAY_DECISION.md; Delivery/HORMONE_MEASUREMENT_DISPLAY_DECISION.md

Remaining discrepancies:
- New chart source awaits actual Run46 compilation, unit execution, simulator visual/accessibility review.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-256 — NOT VERIFIED

Add an educational Hormone Library for the supported hormones.

Original reference: Part 5 / 5C. Hormone Information — new section / 22

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-257 — NOT VERIFIED

Include biological functions, reproductive relevance, measurement limitations, testing context, and appropriate medical guidance.

Original reference: Part 5 / 5C. Hormone Information — new section / 23

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-258 — NOT VERIFIED

Ground educational explanations in approved research.

Original reference: Part 5 / 5C. Hormone Information — new section / 24

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-259 — NOT VERIFIED

Reuse existing hormone artwork.

Original reference: Part 5 / 5C. Hormone Information — new section / 25

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-260 — NOT VERIFIED

Position artwork without interfering with controls or measurements.

Original reference: Part 5 / 5C. Hormone Information — new section / 26

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-261 — PARTIAL

Ensure the feature supports Dynamic Type, VoiceOver, and accessible graph distinctions.

Original reference: Part 5 / 5C. Hormone Information — new section / 27

Source mappings: Fruitfolio/Hormone Information/HormoneInformationView.swift; FruitfolioUITests/HormoneMeasurementUITests.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Actual simulator execution, strict audits and chart/accessibility acceptance remain pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-262 — NOT VERIFIED

Prevent diagnostic conclusions, medication dosing recommendations, or unsupported normal/abnormal classifications.

Original reference: Part 5 / 5C. Hormone Information — new section / 28

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-263 — NOT VERIFIED

Do not automatically share measurements with Ask.

Original reference: Part 5 / 5C. Hormone Information — new section / 29

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-264 — NOT VERIFIED

Require explicit user action before sharing measurements in Ask.

Original reference: Part 5 / 5C. Hormone Information — new section / 30

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-265 — IMPLEMENTED — VERIFICATION PENDING

Ensure deleted measurements are removed from local storage.

Original reference: Part 5 / 5C. Hormone Information — new section / 31

Source mappings: Fruitfolio/Hormone Information/HormoneMeasurement.swift; FruitfolioTests/HormoneMeasurementTests.swift; FruitfolioUITests/HormoneMeasurementUITests.swift; Fruitfolio/Hormone Information/HormoneMeasurementStore.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/Artifacts/Visual/HormoneInformation/manifest.json

Remaining discrepancies:
- New safety path and unaffected save/edit/delete/export journeys require Mac regression verification.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-266 — PARTIAL

Keep Hormone Rhythm and My Measurements as distinct presentations.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 1

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-267 — PARTIAL

Add optional Adjusted Rhythm functionality.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 2

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- A validated adjustment/calibration method and sufficient evidence/context have not been established. Actual points remain separate; no personalized concentrations or unsupported interpolated curves are invented.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-268 — PARTIAL

Allow users to opt into research-supported educational adjustments.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 3

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- A validated adjustment/calibration method and sufficient evidence/context have not been established. Actual points remain separate; no personalized concentrations or unsupported interpolated curves are invented.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-269 — PARTIAL

Use actual measurements as reference points only.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 4

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- A validated adjustment/calibration method and sufficient evidence/context have not been established. Actual points remain separate; no personalized concentrations or unsupported interpolated curves are invented.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-270 — PARTIAL

Adjust educational curves only when sufficient evidence and context exist.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 5

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Actual unsupported-adjustment guard is implemented and unit-tested; exact insufficient-information and restoration UI require completed acceptance. No supported positive adjustment has been demonstrated from the approved evidence. The specification explicitly authorizes retaining original curves when support is insufficient. No founder coefficient decision is invented.
- A validated adjustment/calibration method and sufficient evidence/context have not been established. Actual points remain separate; no personalized concentrations or unsupported interpolated curves are invented.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-271 — NOT VERIFIED

Preserve scientifically established hormone relationships.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 6

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-272 — PARTIAL

Never fabricate a user’s unmeasured hormone concentrations.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 7

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-273 — PARTIAL

Never label adjusted educational curves as actual measured levels.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 8

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-274 — PARTIAL

Distinguish educational curves from actual results with labels, legends, and styling.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 9

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-275 — NOT VERIFIED

Add the specified educational-adjustment disclosure.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 10

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-276 — PARTIAL

Add the specified insufficient-information message.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 11

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-277 — PARTIAL

Allow users to restore the original Hormone Rhythm.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 12

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-278 — PARTIAL

Never overwrite actual measurement records.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 13

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-279 — PARTIAL

Never modify cycle-prediction confidence merely because hormone measurements were entered.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 14

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-280 — PARTIAL

Never use adjusted curves to diagnose, confirm ovulation, establish fertility, or recommend treatment.

Original reference: Part 5 / 5D. Hormone Rhythm integration / 15

Source mappings: Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22MeasurementPresentationPolicy.swift; Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift; FruitfolioTests/Prompt22MeasurementPresentationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md; Delivery/ADJUSTED_RHYTHM_DEPENDENCY.md

Remaining discrepancies:
- Execute actual Xcode unit and Simulator presentation/restore/reference-view journeys.
- Establish a cited, approved scientifically defensible calibration before enabling any adjusted curve; currently original curves are retained.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-281 — PARTIAL

Connect optional My Context information to the relevant Cycle Tracker interpretation systems.

Original reference: Part 6 / 6A. My Context personalization / 281

Source mappings: Fruitfolio/Context Personalization/Prompt27APersonalHealthFields.swift; Fruitfolio/Context Personalization/Prompt27APersonalHealthView.swift; Fruitfolio/Context Personalization/Prompt27AContextModels.swift; Fruitfolio/Context Personalization/Prompt27AContextStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/PERSONAL_HEALTH_CONTEXT_IMPLEMENTATION.md; Delivery/PERSONAL_HEALTH_CONTEXT_IMPLEMENTATION.md

Remaining discrepancies:
- Actual Run46 compilation/unit/UI tests pending. Relevance-limited approved-evidence retrieval and Ask personalization for these new fields remain unfinished; free text does not change prediction math.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-282 — PARTIAL

Make context adaptation evidence-informed.

Original reference: Part 6 / 6A. My Context personalization / 282

Source mappings: Fruitfolio/Context Personalization/Prompt27APersonalHealthFields.swift; Fruitfolio/Context Personalization/Prompt27APersonalHealthView.swift; Fruitfolio/Context Personalization/Prompt27AContextModels.swift; Fruitfolio/Context Personalization/Prompt27AContextStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/PERSONAL_HEALTH_CONTEXT_IMPLEMENTATION.md; Delivery/PERSONAL_HEALTH_CONTEXT_IMPLEMENTATION.md

Remaining discrepancies:
- Actual Run46 compilation/unit/UI tests pending. Relevance-limited approved-evidence retrieval and Ask personalization for these new fields remain unfinished; free text does not change prediction math.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-283 — PARTIAL

Apply relevant context to predictions and educational explanations only where justified.

Original reference: Part 6 / 6A. My Context personalization / 283

Source mappings: Fruitfolio/Context Personalization/Prompt27APersonalHealthFields.swift; Fruitfolio/Context Personalization/Prompt27APersonalHealthView.swift; Fruitfolio/Context Personalization/Prompt27AContextModels.swift; Fruitfolio/Context Personalization/Prompt27AContextStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/PERSONAL_HEALTH_CONTEXT_IMPLEMENTATION.md; Delivery/PERSONAL_HEALTH_CONTEXT_IMPLEMENTATION.md

Remaining discrepancies:
- Actual Run46 compilation/unit/UI tests pending. Relevance-limited approved-evidence retrieval and Ask personalization for these new fields remain unfinished; free text does not change prediction math.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-284 — NOT VERIFIED

Distinguish altered-cycle contexts from ordinary cycle estimates.

Original reference: Part 6 / 6A. My Context personalization / 284

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-285 — NOT VERIFIED

Avoid treating context entries as diagnostic proof.

Original reference: Part 6 / 6A. My Context personalization / 285

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-286 — NOT VERIFIED

Preserve uncertainty when available information is insufficient.

Original reference: Part 6 / 6A. My Context personalization / 286

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-287 — PARTIAL

Ensure context changes do not corrupt previous logs.

Original reference: Part 6 / 6A. My Context personalization / 287

Source mappings: Fruitfolio/Context Personalization/Prompt27APersonalHealthFields.swift; Fruitfolio/Context Personalization/Prompt27APersonalHealthView.swift; Fruitfolio/Context Personalization/Prompt27AContextModels.swift; Fruitfolio/Context Personalization/Prompt27AContextStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/PERSONAL_HEALTH_CONTEXT_IMPLEMENTATION.md; Delivery/PERSONAL_HEALTH_CONTEXT_IMPLEMENTATION.md

Remaining discrepancies:
- Actual Run46 compilation/unit/UI tests pending. Relevance-limited approved-evidence retrieval and Ask personalization for these new fields remain unfinished; free text does not change prediction math.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-288 — NOT VERIFIED

Keep prediction confidence tied to appropriate prediction evidence.

Original reference: Part 6 / 6A. My Context personalization / 288

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-289 — NOT VERIFIED

Ensure context-dependent changes appear consistently in the Today presentation.

Original reference: Part 6 / 6B. Today and cycle visualization / 289

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-290 — NOT VERIFIED

Preserve distinctions between predicted and confirmed biological events.

Original reference: Part 6 / 6B. Today and cycle visualization / 290

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-291 — NOT VERIFIED

Avoid displaying unsupported fertility or ovulation certainty.

Original reference: Part 6 / 6B. Today and cycle visualization / 291

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-292 — NOT VERIFIED

Ensure wheel regions and contextual educational information respond correctly.

Original reference: Part 6 / 6B. Today and cycle visualization / 292

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-293 — NOT VERIFIED

Apply responsive artwork layout to the cycle wheel and surrounding content.

Original reference: Part 6 / 6B. Today and cycle visualization / 293

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-294 — NOT VERIFIED

Apply universal button animation to Today controls.

Original reference: Part 6 / 6B. Today and cycle visualization / 294

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-295 — NOT VERIFIED

Optimize calendar loading and month transitions.

Original reference: Part 6 / 6C. Calendar and logging / 295

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-296 — NOT VERIFIED

Apply the canonical button animation to calendar controls.

Original reference: Part 6 / 6C. Calendar and logging / 296

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-297 — NOT VERIFIED

Apply the same interaction treatment to Log Today and related logging controls.

Original reference: Part 6 / 6C. Calendar and logging / 297

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-298 — NOT VERIFIED

Preserve correct daily-log state when moving between Calendar and Today.

Original reference: Part 6 / 6C. Calendar and logging / 298

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-299 — NOT VERIFIED

Prevent lag during date selection and log opening.

Original reference: Part 6 / 6C. Calendar and logging / 299

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-300 — NOT VERIFIED

Ensure logging overlays use the universal popup and control systems.

Original reference: Part 6 / 6C. Calendar and logging / 300

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-301 — NOT VERIFIED

Keep educational hormone patterns visually separate from user-entered measurements.

Original reference: Part 6 / 6D. Hormone and symptom education / 301

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-302 — NOT VERIFIED

Apply context-appropriate explanatory limitations.

Original reference: Part 6 / 6D. Hormone and symptom education / 302

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-303 — NOT VERIFIED

Preserve accessibility and reduced-motion behavior.

Original reference: Part 6 / 6D. Hormone and symptom education / 303

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-304 — NOT VERIFIED

Apply universal semantic styling to generated educational explanations.

Original reference: Part 6 / 6D. Hormone and symptom education / 304

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-305 — PARTIAL

Replace separate symptom-specific trend presentations with the requested unified symptom-pattern graph.

Original reference: Part 6 / 6E. Trends / 1

Source mappings: Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsView.swift; Fruitfolio/Cycle Tracker/Trends Engine/Prompt24SymptomChartData.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md

Remaining discrepancies:
- Actual unified chart/toggle UI, dense data, Dynamic Type, graph/table VoiceOver and no-data states need current-source verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-306 — PARTIAL

Ensure the graph presents recorded symptom information accurately.

Original reference: Part 6 / 6E. Trends / 2

Source mappings: Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsView.swift; Fruitfolio/Cycle Tracker/Trends Engine/Prompt24SymptomChartData.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md

Remaining discrepancies:
- Actual unified chart/toggle UI, dense data, Dynamic Type, graph/table VoiceOver and no-data states need current-source verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-307 — PARTIAL

Preserve distinctions between actual observations and interpretations.

Original reference: Part 6 / 6E. Trends / 3

Source mappings: Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsView.swift; Fruitfolio/Cycle Tracker/Trends Engine/Prompt24SymptomChartData.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md

Remaining discrepancies:
- Actual unified chart/toggle UI, dense data, Dynamic Type, graph/table VoiceOver and no-data states need current-source verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-308 — PARTIAL

Do not manufacture trends when insufficient data exists.

Original reference: Part 6 / 6E. Trends / 4

Source mappings: Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsView.swift; Fruitfolio/Cycle Tracker/Trends Engine/Prompt24SymptomChartData.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md

Remaining discrepancies:
- Actual unified chart/toggle UI, dense data, Dynamic Type, graph/table VoiceOver and no-data states need current-source verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-309 — PARTIAL

Make the graph responsive and accessible.

Original reference: Part 6 / 6E. Trends / 5

Source mappings: Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsView.swift; Fruitfolio/Cycle Tracker/Trends Engine/Prompt24SymptomChartData.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/UNIFIED_SYMPTOM_TIMELINE_REPAIR.md

Remaining discrepancies:
- Actual unified chart/toggle UI, dense data, Dynamic Type, graph/table VoiceOver and no-data states need current-source verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-310 — NOT VERIFIED

Apply shared responsive artwork placement to relevant scientific education screens.

Original reference: Part 6 / 6F. Scientific education modules / 310

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-311 — NOT VERIFIED

Preserve the correct relationship between scientific illustrations and explanations.

Original reference: Part 6 / 6F. Scientific education modules / 311

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-312 — NOT VERIFIED

Prevent decorative artwork from interfering with interactive scientific hotspots.

Original reference: Part 6 / 6F. Scientific education modules / 312

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-313 — NOT VERIFIED

Apply the shared semantic text system to generated explanations.

Original reference: Part 6 / 6F. Scientific education modules / 313

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-314 — NOT VERIFIED

Keep medically sensitive educational personalization appropriately qualified.

Original reference: Part 6 / 6F. Scientific education modules / 314

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-315 — PARTIAL

Implement the added LifeBridge information-access requirement within Fruitfolio.

Original reference: Part 6 / 6G. LifeBridge information / 1

Source mappings: Fruitfolio/LifeBridge/LifeBridgeInformation.swift; Fruitfolio/LifeBridge/LifeBridgeInformationView.swift; Fruitfolio/LifeBridgeApprovedSourceDirectory.json; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md; Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md

Remaining discrepancies:
- Approved licensed local snapshots from both named websites and applicable founder/referral/commission review remain unavailable.
- New source and tests require actual Xcode execution; app-wide localization and full visual/accessibility acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-316 — PARTIAL

Use the founder-corrected LifeBridge source-of-truth rule.

Original reference: Part 6 / 6G. LifeBridge information / 2

Source mappings: Fruitfolio/LifeBridge/LifeBridgeInformation.swift; Fruitfolio/LifeBridge/LifeBridgeInformationView.swift; Fruitfolio/LifeBridgeApprovedSourceDirectory.json; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md; Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md

Remaining discrepancies:
- Approved licensed local snapshots from both named websites and applicable founder/referral/commission review remain unavailable.
- New source and tests require actual Xcode execution; app-wide localization and full visual/accessibility acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-317 — PARTIAL

Ensure the feature provides the authorized informational access described in Prompt 1B.

Original reference: Part 6 / 6G. LifeBridge information / 3

Source mappings: Fruitfolio/LifeBridge/LifeBridgeInformation.swift; Fruitfolio/LifeBridge/LifeBridgeInformationView.swift; Fruitfolio/LifeBridgeApprovedSourceDirectory.json; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md; Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md

Remaining discrepancies:
- Approved licensed local snapshots from both named websites and applicable founder/referral/commission review remain unavailable.
- New source and tests require actual Xcode execution; app-wide localization and full visual/accessibility acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-318 — PARTIAL

Preserve appropriate privacy, research, and medical-safety boundaries.

Original reference: Part 6 / 6G. LifeBridge information / 4

Source mappings: Fruitfolio/LifeBridge/LifeBridgeInformation.swift; Fruitfolio/LifeBridge/LifeBridgeInformationView.swift; Fruitfolio/LifeBridgeApprovedSourceDirectory.json; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md; Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md

Remaining discrepancies:
- Approved licensed local snapshots from both named websites and applicable founder/referral/commission review remain unavailable.
- New source and tests require actual Xcode execution; app-wide localization and full visual/accessibility acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-319 — NOT VERIFIED

Avoid treating LifeBridge information as automatically available for unrelated AI claims.

Original reference: Part 6 / 6G. LifeBridge information / 5

Source mappings: Fruitfolio/LifeBridge/LifeBridgeInformation.swift; Fruitfolio/LifeBridge/LifeBridgeInformationView.swift; Fruitfolio/LifeBridgeApprovedSourceDirectory.json; Fruitfolio/Hub/FAQ/Prompt29FAQView.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md; Delivery/LIFEBRIDGE_CONTENT_BOUNDARY.md

Remaining discrepancies:
- Approved licensed local snapshots from both named websites and applicable founder/referral/commission review remain unavailable.
- New source and tests require actual Xcode execution; app-wide localization and full visual/accessibility acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-320 — NOT VERIFIED

Apply the founder’s revised Fruit Basket home text.

Original reference: Part 7 / 7A. Text and interface / 320

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-321 — NOT VERIFIED

Apply the revised How It Works instructions.

Original reference: Part 7 / 7A. Text and interface / 321

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-322 — NOT VERIFIED

Apply the revised topic-selection wording.

Original reference: Part 7 / 7A. Text and interface / 322

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-323 — NOT VERIFIED

Explain starred fruit, unstarred fruit, and standalone stars.

Original reference: Part 7 / 7A. Text and interface / 323

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-324 — NOT VERIFIED

Apply the universal popup system.

Original reference: Part 7 / 7A. Text and interface / 324

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-325 — PARTIAL

Apply canonical semantic styling and appropriate Fruitfolio dialogue rules.

Original reference: Part 7 / 7A. Text and interface / 325

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/FruitBasketGroundedResearchTests.swift; FruitfolioUITests/FruitBasketGroundedJourneyUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/SOURCE89_GROUNDED_GAME_AND_ACCESSIBILITY.md; Delivery/SOURCE90_GAME_JOURNEY_AND_TRANSLATION_REGRESSIONS.md

Remaining discrepancies:
- Retrieve current Apple repair-batch and focused gameplay evidence; finish exact visual/semantic/difficulty acceptance. Deterministic quote fallback is bounded, not full AI educational-generation acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-326 — PARTIAL

Preserve the required order: answer the question → catch fruit → reveal basket.

Original reference: Part 7 / 7B. Game rules / 1

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/FruitBasketGroundedResearchTests.swift; FruitfolioUITests/FruitBasketGroundedJourneyUITests.swift

Source-sprint records: Delivery/FiveHour_Phase5_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/SOURCE89_GROUNDED_GAME_AND_ACCESSIBILITY.md; Delivery/SOURCE90_GAME_JOURNEY_AND_TRANSLATION_REGRESSIONS.md

Remaining discrepancies:
- Retrieve current Apple repair-batch and focused gameplay evidence; finish exact visual/semantic/difficulty acceptance. Deterministic quote fallback is bounded, not full AI educational-generation acceptance.
- Run new lifecycle tests and complete actual game UI sequence on founder Mac. These source changes do not establish full gameplay acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-327 — PARTIAL

Make the game distinguish between good fruit, bad fruit, and standalone stars.

Original reference: Part 7 / 7B. Game rules / 2

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/FRUIT_BASKET_RAIN_AND_MARKER_REPAIR.md; Delivery/FRUIT_BASKET_RAIN_AND_MARKER_REPAIR.md

Remaining discrepancies:
- Actual Xcode unit execution, gameplay/screenshot/motion and accessibility acceptance pending.
- Remaining Fruit Basket obstacle, storm, catch-settling and full-round requirements are not claimed complete.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-328 — PARTIAL

Introduce standalone stars as rare beneficial drops.

Original reference: Part 7 / 7B. Game rules / 3

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Catch mode retains rare standalone-star entry/settling. Classification controls currently lack standalone-star acquisition; no automatic award or invented substitute mechanic was added.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-329 — PARTIAL

Allow players to catch standalone stars independently of fruit.

Original reference: Part 7 / 7B. Game rules / 4

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Catch mode retains rare standalone-star entry/settling. Classification controls currently lack standalone-star acquisition; no automatic award or invented substitute mechanic was added.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-330 — IMPLEMENTED — VERIFICATION PENDING

Make each collected star grant one star pass.

Original reference: Part 7 / 7B. Game rules / 5

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run89/RepairBatch/Build/xcode-repair-batch-test.log; Delivery/LatestAppleTestResults.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run89/RepairBatch/Build/xcode-repair-batch-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-331 — IMPLEMENTED — VERIFICATION PENDING

Allow star passes to accumulate without a fixed maximum.

Original reference: Part 7 / 7B. Game rules / 6

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/Prompt28FruitBasketTests.swift; Fruitfolio/Fruit Basket/Prompt28BasketArtworkProjection.swift

Source-sprint records: Delivery/FiveHour_Phase5_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run85/UnitBuild/xcode-unit-test.log; Delivery/LatestAppleTestResults.json; Fruitfolio_Verification_Evidence/AppleRuns/Run85/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Run full normal/largest game UI journeys, reveal screenshots, strict accessibility, restart/source snapshots and animation recordings.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-332 — IMPLEMENTED — VERIFICATION PENDING

Consume exactly one star pass when a bad-fruit catch triggers its protective use.

Original reference: Part 7 / 7B. Game rules / 7

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run85/UnitBuild/xcode-unit-test.log; Delivery/LatestAppleTestResults.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run85/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-333 — IMPLEMENTED — VERIFICATION PENDING

Allow the round to continue when a star pass protects against an otherwise round-ending bad-fruit catch.

Original reference: Part 7 / 7B. Game rules / 8

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run89/RepairBatch/Build/xcode-repair-batch-test.log; Delivery/LatestAppleTestResults.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run89/RepairBatch/Build/xcode-repair-batch-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-334 — IMPLEMENTED — VERIFICATION PENDING

Do not count standalone stars toward the good-fruit basket target.

Original reference: Part 7 / 7B. Game rules / 9

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift; Fruitfolio/Fruit Basket/Prompt28BasketArtworkProjection.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: Delivery/FiveHour_Phase5_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run85/UnitBuild/xcode-unit-test.log; Delivery/LatestAppleTestResults.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run85/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Run full normal/largest game UI journeys, reveal screenshots, strict accessibility, restart/source snapshots and animation recordings.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-335 — PARTIAL

Require stars to fully enter the basket before being counted.

Original reference: Part 7 / 7B. Game rules / 10

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/Prompt28FruitBasketTests.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift; FruitfolioTests/FruitBasketGroundedResearchTests.swift; FruitfolioUITests/FruitBasketGroundedJourneyUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/SOURCE89_GROUNDED_GAME_AND_ACCESSIBILITY.md; Delivery/SOURCE90_GAME_JOURNEY_AND_TRANSLATION_REGRESSIONS.md

Remaining discrepancies:
- Retrieve current Apple repair-batch and focused gameplay evidence; finish exact visual/semantic/difficulty acceptance. Deterministic quote fallback is bounded, not full AI educational-generation acceptance.
- Catch mode retains rare standalone-star entry/settling. Classification controls currently lack standalone-star acquisition; no automatic award or invented substitute mechanic was added.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-336 — PARTIAL

Apply the same convincing flattened/settled catch treatment to stars and fruit.

Original reference: Part 7 / 7B. Game rules / 11

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/Prompt28FruitBasketTests.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift; FruitfolioTests/FruitBasketGroundedResearchTests.swift; FruitfolioUITests/FruitBasketGroundedJourneyUITests.swift; Fruitfolio/Fruit Basket/Prompt28StormNoticeView.swift

Source-sprint records: Delivery/FiveHour_Phase5_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/SOURCE89_GROUNDED_GAME_AND_ACCESSIBILITY.md; Delivery/SOURCE90_GAME_JOURNEY_AND_TRANSLATION_REGRESSIONS.md

Remaining discrepancies:
- Retrieve current Apple repair-batch and focused gameplay evidence; finish exact visual/semantic/difficulty acceptance. Deterministic quote fallback is bounded, not full AI educational-generation acceptance.
- Run native hosted test, full normal/largest/reduced-motion game journeys and actual animation capture on founder Mac.
- Catch mode retains rare standalone-star entry/settling. Classification controls currently lack standalone-star acquisition; no automatic award or invented substitute mechanic was added.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-337 — PARTIAL

Ensure star drops remain genuinely rare.

Original reference: Part 7 / 7B. Game rules / 12

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Catch mode retains rare standalone-star entry/settling. Classification controls currently lack standalone-star acquisition; no automatic award or invented substitute mechanic was added.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-338 — PARTIAL

Update all game instructions and feedback to reflect the implemented star-pass rules.

Original reference: Part 7 / 7B. Game rules / 13

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Run new Apple unit/frame tests; capture actual gameplay settling frames including Reduce Motion; perform focused visual comparison.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-339 — NOT VERIFIED

Implement wind movement in code rather than relying solely on animated artwork.

Original reference: Part 7 / 7C. Weather and obstacles / 339

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-340 — NOT VERIFIED

Use the existing wind artwork as the visual reference.

Original reference: Part 7 / 7C. Weather and obstacles / 340

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-341 — NOT VERIFIED

Make wind alter fruit trajectories slightly.

Original reference: Part 7 / 7C. Weather and obstacles / 341

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-342 — NOT VERIFIED

Play the appropriate wind audio.

Original reference: Part 7 / 7C. Weather and obstacles / 342

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-343 — NOT VERIFIED

Use existing rain and rain-cloud artwork for soft rain.

Original reference: Part 7 / 7C. Weather and obstacles / 343

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-344 — IMPLEMENTED — VERIFICATION PENDING

Make rain produce puddle obstacles.

Original reference: Part 7 / 7C. Weather and obstacles / 344

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/FRUIT_BASKET_RAIN_AND_MARKER_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/FRUIT_BASKET_RAIN_AND_MARKER_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-345 — PARTIAL

Animate puddles subtly while preserving the original artwork.

Original reference: Part 7 / 7C. Weather and obstacles / 345

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/FRUIT_BASKET_STORM_AND_LIFECYCLE.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/FRUIT_BASKET_STORM_AND_LIFECYCLE.md

Remaining discrepancies:
- Actual required visual/audio/accessibility and current-source acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-346 — PARTIAL

Display Strawberry’s specified storm popup using the existing large contact-card artwork.

Original reference: Part 7 / 7C. Weather and obstacles / 346

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/FRUIT_BASKET_STORM_AND_LIFECYCLE.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/FRUIT_BASKET_STORM_AND_LIFECYCLE.md

Remaining discrepancies:
- Actual required visual/audio/accessibility and current-source acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-347 — PARTIAL

Include the specified storm dialogue.

Original reference: Part 7 / 7C. Weather and obstacles / 347

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/FRUIT_BASKET_STORM_AND_LIFECYCLE.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/FRUIT_BASKET_STORM_AND_LIFECYCLE.md

Remaining discrepancies:
- Actual required visual/audio/accessibility and current-source acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-348 — NOT VERIFIED

Add basket inertia while the basket physically passes through a puddle.

Original reference: Part 7 / 7C. Weather and obstacles / 348

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-349 — PARTIAL

Visually communicate the basket’s resistance.

Original reference: Part 7 / 7C. Weather and obstacles / 349

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/FRUIT_BASKET_RAIN_AND_MARKER_REPAIR.md; Delivery/FRUIT_BASKET_RAIN_AND_MARKER_REPAIR.md

Remaining discrepancies:
- Actual Xcode unit execution, gameplay/screenshot/motion and accessibility acceptance pending.
- Remaining Fruit Basket obstacle, storm, catch-settling and full-round requirements are not claimed complete.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-350 — IMPLEMENTED — VERIFICATION PENDING

Restore normal movement after leaving the puddle.

Original reference: Part 7 / 7C. Weather and obstacles / 350

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/FRUIT_BASKET_RAIN_AND_MARKER_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/FRUIT_BASKET_RAIN_AND_MARKER_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-351 — PARTIAL

Position branch obstacles as though growing from the screen edge.

Original reference: Part 7 / 7C. Weather and obstacles / 351

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/BRANCH_CONTACT_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/BRANCH_CONTACT_REPAIR.md

Remaining discrepancies:
- Actual required visual/audio/accessibility and current-source acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-352 — PARTIAL

Make fruit bounce off branches and change trajectory.

Original reference: Part 7 / 7C. Weather and obstacles / 352

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/BRANCH_CONTACT_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/BRANCH_CONTACT_REPAIR.md

Remaining discrepancies:
- Actual required visual/audio/accessibility and current-source acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-353 — IMPLEMENTED — VERIFICATION PENDING

Make vines slow good fruit passing through them.

Original reference: Part 7 / 7C. Weather and obstacles / 353

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-354 — IMPLEMENTED — VERIFICATION PENDING

Make vines slow standalone stars.

Original reference: Part 7 / 7C. Weather and obstacles / 354

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-355 — IMPLEMENTED — VERIFICATION PENDING

Prevent bad fruit from using the vine-slowing interaction.

Original reference: Part 7 / 7C. Weather and obstacles / 355

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-356 — PARTIAL

Play rustling audio when appropriate objects contact vines.

Original reference: Part 7 / 7C. Weather and obstacles / 356

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md

Remaining discrepancies:
- Actual required visual/audio/accessibility and current-source acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-357 — PARTIAL

Make vine resistance visibly believable rather than merely changing an invisible velocity value.

Original reference: Part 7 / 7C. Weather and obstacles / 357

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/VINE_CONTACT_REPAIR.md

Remaining discrepancies:
- Actual required visual/audio/accessibility and current-source acceptance pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-358 — PARTIAL

Increase falling speed gradually as game levels advance.

Original reference: Part 7 / 7D. Difficulty progression / 358

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Complete rendered progression/comfort and relevant actual gameplay acceptance remains unverified. Bounded unit cases do not prove every interaction.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-359 — PARTIAL

Base progression primarily on successfully completed rounds.

Original reference: Part 7 / 7D. Difficulty progression / 359

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift

Source-sprint records: Delivery/FiveHour_Phase7_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Complete rendered progression/comfort and relevant actual gameplay acceptance remains unverified. Bounded unit cases do not prove every interaction.
- Run full gameplay/persistence/UI regressions and process-restart journeys on founder Mac; source fixtures do not establish physical-device kill durability.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-360 — PARTIAL

Keep early levels slow and forgiving.

Original reference: Part 7 / 7D. Difficulty progression / 360

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Complete rendered progression/comfort and relevant actual gameplay acceptance remains unverified. Bounded unit cases do not prove every interaction.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-361 — PARTIAL

Introduce bounded difficulty increases at later levels.

Original reference: Part 7 / 7D. Difficulty progression / 361

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Complete rendered progression/comfort and relevant actual gameplay acceptance remains unverified. Bounded unit cases do not prove every interaction.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-362 — PARTIAL

Do not increase difficulty after an unsuccessful round.

Original reference: Part 7 / 7D. Difficulty progression / 362

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Complete rendered progression/comfort and relevant actual gameplay acceptance remains unverified. Bounded unit cases do not prove every interaction.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-363 — PARTIAL

Stop increasing difficulty after the tested maximum level.

Original reference: Part 7 / 7D. Difficulty progression / 363

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Complete rendered progression/comfort and relevant actual gameplay acceptance remains unverified. Bounded unit cases do not prove every interaction.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-364 — PARTIAL

Never change an object’s velocity while it is already falling.

Original reference: Part 7 / 7D. Difficulty progression / 364

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Complete rendered progression/comfort and relevant actual gameplay acceptance remains unverified. Bounded unit cases do not prove every interaction.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-365 — PARTIAL

Keep gameplay challenging but not excessively demanding.

Original reference: Part 7 / 7D. Difficulty progression / 365

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Complete rendered progression/comfort and relevant actual gameplay acceptance remains unverified. Bounded unit cases do not prove every interaction.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-366 — IMPLEMENTED — VERIFICATION PENDING

Trigger basket reveal after the actual round finishes.

Original reference: Part 7 / 7E. Results and leaderboard / 366

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; FruitfolioTests/Prompt28FruitBasketTests.swift; Fruitfolio/Fruit Basket/Prompt28BasketArtworkProjection.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift

Source-sprint records: Delivery/FiveHour_Phase5_RequirementChanges.json; Delivery/FiveHour_Phase7_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Complete rendered progression/comfort and relevant actual gameplay acceptance remains unverified. Bounded unit cases do not prove every interaction.
- Run full normal/largest game UI journeys, reveal screenshots, strict accessibility, restart/source snapshots and animation recordings.
- Run full gameplay/persistence/UI regressions and process-restart journeys on founder Mac; source fixtures do not establish physical-device kill durability.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-367 — PARTIAL

Include accumulated fruit, stars, rewards, and consequences in the result.

Original reference: Part 7 / 7E. Results and leaderboard / 367

Source mappings: Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/Prompt28FruitBasketTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/RUN92_VERIFICATION_AND_REPAIRS.json

Remaining discrepancies:
- Inspect/verify full relevant rendered UI and accessibility states; passing underlying frame/persistence tests do not establish complete feature acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-368 — NOT VERIFIED

Update leaderboard instructions and game rules to match the final mechanics.

Original reference: Part 7 / 7E. Results and leaderboard / 368

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-369 — IMPLEMENTED — VERIFICATION PENDING

Share one username source between Account and Fruit Basket.

Original reference: Part 7 / 7E. Results and leaderboard / 369

Source mappings: Fruitfolio/Privacy Settings/Prompt12AccountView.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-370 — IMPLEMENTED — VERIFICATION PENDING

Allow username creation and editing from both locations.

Original reference: Part 7 / 7E. Results and leaderboard / 370

Source mappings: Fruitfolio/Privacy Settings/Prompt12AccountView.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-371 — NOT VERIFIED

Apply non-explicit and non-real-name username requirements.

Original reference: Part 7 / 7E. Results and leaderboard / 371

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-372 — NOT VERIFIED

Update accessibility descriptions, FAQs, and tests to match the corrected gameplay.

Original reference: Part 7 / 7E. Results and leaderboard / 372

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-373 — IMPLEMENTED — VERIFICATION PENDING

Remove bold formatting from FAQ questions.

Original reference: Part 8 / 8A. FAQ / 373

Source mappings: Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/E8B8B094-0C7E-4A0C-AE42-1FFBFDF3D86D.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/E8B8B094-0C7E-4A0C-AE42-1FFBFDF3D86D.png

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-374 — BLOCKED

Use the existing approved tulip artwork.

Original reference: Part 8 / 8A. FAQ / 374

Source mappings: Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/IMPLEMENTATION_PASS_RESOURCE_INTEGRITY.json; Delivery/IMPLEMENTATION_PASS_RESOURCE_INTEGRITY.json

Remaining discrepancies:
- Missing identifiable approved tulip resource or authoritative mapping to an existing resource; unrelated implementation continues.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-375 — IMPLEMENTED — VERIFICATION PENDING

Use the existing sparkle artwork.

Original reference: Part 8 / 8A. FAQ / 375

Source mappings: Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/E8B8B094-0C7E-4A0C-AE42-1FFBFDF3D86D.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/E8B8B094-0C7E-4A0C-AE42-1FFBFDF3D86D.png

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-376 — IMPLEMENTED — VERIFICATION PENDING

Add an approved cloud only if a suitable asset already exists.

Original reference: Part 8 / 8A. FAQ / 376

Source mappings: Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/E8B8B094-0C7E-4A0C-AE42-1FFBFDF3D86D.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/E8B8B094-0C7E-4A0C-AE42-1FFBFDF3D86D.png

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-377 — IMPLEMENTED — VERIFICATION PENDING

Do not substitute an unrelated rain cloud simply because it is available.

Original reference: Part 8 / 8A. FAQ / 377

Source mappings: Fruitfolio/Hub/FAQ/Prompt29FAQView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/E8B8B094-0C7E-4A0C-AE42-1FFBFDF3D86D.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/E8B8B094-0C7E-4A0C-AE42-1FFBFDF3D86D.png

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-378 — NOT VERIFIED

Apply universal popup and decorative artwork rules.

Original reference: Part 8 / 8A. FAQ / 378

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-379 — IMPLEMENTED — VERIFICATION PENDING

Use the existing green flecks artwork.

Original reference: Part 8 / 8B. Contact / 379

Source mappings: Fruitfolio/Hub/Contact/Prompt30ContactView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/2F875D1C-4426-445B-BBF8-F33BD0D0789D.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/2F875D1C-4426-445B-BBF8-F33BD0D0789D.png

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-380 — IMPLEMENTED — VERIFICATION PENDING

Use the existing plum artwork.

Original reference: Part 8 / 8B. Contact / 380

Source mappings: Fruitfolio/Hub/Contact/Prompt30ContactView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/2F875D1C-4426-445B-BBF8-F33BD0D0789D.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/2F875D1C-4426-445B-BBF8-F33BD0D0789D.png

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-381 — IMPLEMENTED — VERIFICATION PENDING

Use the existing sparkles.

Original reference: Part 8 / 8B. Contact / 381

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/2F875D1C-4426-445B-BBF8-F33BD0D0789D.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/2F875D1C-4426-445B-BBF8-F33BD0D0789D.png

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-382 — IMPLEMENTED — VERIFICATION PENDING

Correct any conflicting older artwork assignments.

Original reference: Part 8 / 8B. Contact / 382

Source mappings: Fruitfolio/Hub/Contact/Prompt30ContactView.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/2F875D1C-4426-445B-BBF8-F33BD0D0789D.png; Fruitfolio_Verification_Evidence/AppleRuns/Run35/FocusedJourneys/Visual/SharedControls/2F875D1C-4426-445B-BBF8-F33BD0D0789D.png

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-383 — NOT VERIFIED

Preserve the intended composition through responsive placement.

Original reference: Part 8 / 8B. Contact / 383

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-384 — NOT VERIFIED

Remove remaining inconsistent gray/red buttons.

Original reference: Part 8 / 8C. Remaining application-wide cleanup / 384

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-385 — NOT VERIFIED

Remove duplicated or incorrectly layered decorative artwork.

Original reference: Part 8 / 8C. Remaining application-wide cleanup / 385

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-386 — NOT VERIFIED

Correct text that clips or overlaps artwork.

Original reference: Part 8 / 8C. Remaining application-wide cleanup / 386

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-387 — NOT VERIFIED

Correct popup text that exceeds its writing area.

Original reference: Part 8 / 8C. Remaining application-wide cleanup / 387

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-388 — NOT VERIFIED

Ensure all relevant character dialogue receives the shared semantic styling.

Original reference: Part 8 / 8C. Remaining application-wide cleanup / 388

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-389 — NOT VERIFIED

Correct inconsistent button animations and popup sounds.

Original reference: Part 8 / 8C. Remaining application-wide cleanup / 389

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-390 — NOT VERIFIED

Apply the updated accessibility behavior to all affected states.

Original reference: Part 8 / 8C. Remaining application-wide cleanup / 390

Source mappings: Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-391 — PARTIAL

Add one global language selector in Settings.

Original reference: Part 9 / 9A. App-wide language system / 391

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-392 — PARTIAL

Create one persistent source of truth for the selected language.

Original reference: Part 9 / 9A. App-wide language system / 392

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-393 — PARTIAL

Synchronize that language across all screens.

Original reference: Part 9 / 9A. App-wide language system / 393

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift

Source-sprint records: Delivery/FiveHour_Phase6_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-394 — PARTIAL

Include onboarding, Hub, Ask, My Encyclopedias, Guide Builder, Cycle Tracker, Hormone Information, Fruit Basket, FAQ, Contact, Account, Privacy, and Purchase.

Original reference: Part 9 / 9A. App-wide language system / 394

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-395 — PARTIAL

Translate popups, notifications, validation messages, errors, and accessibility labels.

Original reference: Part 9 / 9A. App-wide language system / 395

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-396 — PARTIAL

Translate applicable fruit-character dialogue and dynamically generated content.

Original reference: Part 9 / 9A. App-wide language system / 396

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-397 — PARTIAL

Remove hard-coded English strings that bypass the selected language.

Original reference: Part 9 / 9A. App-wide language system / 397

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift

Source-sprint records: Delivery/FiveHour_Phase6_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-398 — IMPLEMENTED — VERIFICATION PENDING

Persist the language preference across restarts and navigation.

Original reference: Part 9 / 9A. App-wide language system / 398

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift

Source-sprint records: Delivery/FiveHour_Phase6_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Run actual Settings recovery notices, language restart/RTL journeys and existing preferences/audio regression on founder Mac.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-399 — IMPLEMENTED — VERIFICATION PENDING

Ensure users can always understand and access the language selector.

Original reference: Part 9 / 9A. App-wide language system / 399

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift

Source-sprint records: Delivery/FiveHour_Phase6_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-400 — PARTIAL

Support the specified major African languages.

Original reference: Part 9 / 9B. Language coverage / 400

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-401 — PARTIAL

Support the specified major Asian languages.

Original reference: Part 9 / 9B. Language coverage / 401

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift

Source-sprint records: Delivery/FiveHour_Phase6_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-402 — PARTIAL

Support the specified major Middle Eastern languages.

Original reference: Part 9 / 9B. Language coverage / 402

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-403 — PARTIAL

Support the specified major European languages.

Original reference: Part 9 / 9B. Language coverage / 403

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-404 — PARTIAL

Support the specified major Pacific Islander languages.

Original reference: Part 9 / 9B. Language coverage / 404

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-405 — PARTIAL

Support the specified major South American languages.

Original reference: Part 9 / 9B. Language coverage / 405

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-406 — PARTIAL

Include relevant regional and Indigenous languages within that scope.

Original reference: Part 9 / 9B. Language coverage / 406

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-407 — PARTIAL

Identify languages individually rather than using labels such as “African” or “Indian.”

Original reference: Part 9 / 9B. Language coverage / 407

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-408 — IMPLEMENTED — VERIFICATION PENDING

Build an extensible language architecture.

Original reference: Part 9 / 9B. Language coverage / 408

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift

Source-sprint records: Delivery/FiveHour_Phase6_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-409 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Verify actual model/runtime support rather than assuming every requested language works.

Original reference: Part 9 / 9B. Language coverage / 409

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-410 — PARTIAL

Support right-to-left writing systems where required.

Original reference: Part 9 / 9C. Layout and writing systems / 410

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-411 — PARTIAL

Adapt layout to different text lengths and writing systems.

Original reference: Part 9 / 9C. Layout and writing systems / 411

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-412 — PARTIAL

Prevent translated text from clipping or overflowing.

Original reference: Part 9 / 9C. Layout and writing systems / 412

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-413 — PARTIAL

Prevent translated text from colliding with artwork.

Original reference: Part 9 / 9C. Layout and writing systems / 413

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-414 — PARTIAL

Allow responsive container growth and scrolling.

Original reference: Part 9 / 9C. Layout and writing systems / 414

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-415 — PARTIAL

Preserve readable font sizes.

Original reference: Part 9 / 9C. Layout and writing systems / 415

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-416 — PARTIAL

Support Dynamic Type.

Original reference: Part 9 / 9C. Layout and writing systems / 416

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-417 — PARTIAL

Preserve Fruitfolio’s visual hierarchy, tone, and appropriate kaomoji usage.

Original reference: Part 9 / 9C. Layout and writing systems / 417

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-418 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Integrate the approved MADLAD model into the actual SwiftUI application.

Original reference: Part 9 / 9D. MADLAD integration / 418

Source mappings: 

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/MADLAD_ActualAppleRuntime.txt; Fruitfolio_Verification_Evidence/AppleRuns/Run35/MADLAD_ActualAppleRuntime.txt

Remaining discrepancies:
- Complete app-wide localization and grounded Ask translation routing with strict preservation.
- Resolve and verify required language tags and quality; five exact tags absent.
- Verify physical iPhone memory, performance, offline restart and distribution constraints.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-419 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Implement working local inference.

Original reference: Part 9 / 9D. MADLAD integration / 419

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md

Remaining discrepancies:
- Production Ask remains gated pending semantic/language/device acceptance. New adapter, explicit execution-thread evidence and disabled-network device tests remain unverified.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-420 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Connect the selected language to the Ask translation pipeline.

Original reference: Part 9 / 9D. MADLAD integration / 420

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json; Delivery/RUN61_VERIFICATION.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json; Delivery/RUN61_VERIFICATION.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md

Remaining discrepancies:
- Actual new fixture outputs, clinical distinctions/uncertainty/safety preservation and app-wide display synchronization not yet accepted.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-421 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Translate grounded answers after research and evidence validation.

Original reference: Part 9 / 9D. MADLAD integration / 421

Source mappings: 

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json; Delivery/RUN61_VERIFICATION.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json; Delivery/RUN61_VERIFICATION.md

Remaining discrepancies:
- Complete production language-aware post-grounding translation with sufficient safety/quality verification; do not substitute cloud or another model.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-422 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Preserve citations, scientific meaning, numerical values, and safety warnings.

Original reference: Part 9 / 9D. MADLAD integration / 422

Source mappings: TranslationInvestigation/madlad-candle-probe/src/main.rs; Tools/repack_madlad_for_llama.py; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift; FruitfolioTests/TranslationPreservationTests.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/MADLAD/candle-original-paragraph.stdout.json; Fruitfolio_Verification_Evidence/MADLAD/RESULT.md; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Delivery/LatestAppleTestResults.json; Fruitfolio_Verification_Evidence/MADLAD/candle-original-paragraph.stdout.json; Fruitfolio_Verification_Evidence/MADLAD/RESULT.md; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md

Remaining discrepancies:
- Bounded fixture PASS does not verify general clinical entailment, all required languages, arbitrary safety statements, script distinction or device acceptance. Production Ask translation remains gated.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-423 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Preserve uncertainty and unsupported-evidence distinctions.

Original reference: Part 9 / 9D. MADLAD integration / 423

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-424 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Prevent translation from introducing new medical claims.

Original reference: Part 9 / 9D. MADLAD integration / 424

Source mappings: TranslationInvestigation/madlad-candle-probe/src/main.rs; Tools/repack_madlad_for_llama.py; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift; FruitfolioTests/TranslationPreservationTests.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/MADLAD/candle-original-paragraph.stdout.json; Fruitfolio_Verification_Evidence/MADLAD/RESULT.md; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md; Fruitfolio_Verification_Evidence/MADLAD/candle-original-paragraph.stdout.json; Fruitfolio_Verification_Evidence/MADLAD/RESULT.md; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md

Remaining discrepancies:
- Actual new fixture outputs, clinical distinctions/uncertainty/safety preservation and app-wide display synchronization not yet accepted.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-425 — PARTIAL

Handle unavailable models and unsupported languages gracefully.

Original reference: Part 9 / 9D. MADLAD integration / 425

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-426 — PARTIAL

Prevent incomplete translations from appearing complete.

Original reference: Part 9 / 9D. MADLAD integration / 426

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md

Remaining discrepancies:
- Actual new fixture outputs, clinical distinctions/uncertainty/safety preservation and app-wide display synchronization not yet accepted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-427 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Keep inference off the main UI thread.

Original reference: Part 9 / 9D. MADLAD integration / 427

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run48/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run48/UnitBuild/UnitAttachments/manifest.json; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run48/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run48/UnitBuild/UnitAttachments/manifest.json

Remaining discrepancies:
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.

## FF1B-428 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Avoid excessive memory consumption.

Original reference: Part 9 / 9D. MADLAD integration / 428

Source mappings: 

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md

Remaining discrepancies:
- Physical-iPhone memory, representative long inputs, runtime coexistence and device/distribution constraints remain NOT VERIFIED.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-429 — IMPLEMENTED — VERIFICATION PENDING

Do not silently reset the selected language.

Original reference: Part 9 / 9D. MADLAD integration / 429

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: Delivery/FiveHour_Phase6_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Run actual Settings recovery notices, language restart/RTL journeys and existing preferences/audio regression on founder Mac.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-430 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Ensure translation operates without internet access, cloud APIs, remote inference, or Ollama.

Original reference: Part 9 / 9D. MADLAD integration / 430

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/xcode-offline-madlad-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/xcode-offline-madlad-test.log

Remaining discrepancies:
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.

## FF1B-431 — NOT VERIFIED

Preserve original saved content when switching languages.

Original reference: Part 9 / 9E. Saved content and verification / 431

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-432 — NOT VERIFIED

Preserve user-entered notes and measurements.

Original reference: Part 9 / 9E. Saved content and verification / 432

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-433 — PARTIAL

Preserve citations and metadata.

Original reference: Part 9 / 9E. Saved content and verification / 433

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md

Remaining discrepancies:
- Actual new fixture outputs, clinical distinctions/uncertainty/safety preservation and app-wide display synchronization not yet accepted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-434 — IMPLEMENTED — VERIFICATION PENDING

Do not silently overwrite user-authored content with translations.

Original reference: Part 9 / 9E. Saved content and verification / 434

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift

Source-sprint records: Delivery/FiveHour_Phase6_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md; Fruitfolio_Verification_Evidence/AppleRuns/Run66/UnitBuild/actual-test-executions.json; Delivery/TRANSLATION_LAYOUT_AND_MULTILINGUAL_VERIFICATION.md

Remaining discrepancies:
- Actual new fixture outputs, clinical distinctions/uncertainty/safety preservation and app-wide display synchronization not yet accepted.
- Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-435 — NOT VERIFIED

Verify the selected language across every applicable feature.

Original reference: Part 9 / 9E. Saved content and verification / 435

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-436 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Verify Ask responses in each supported language.

Original reference: Part 9 / 9E. Saved content and verification / 436

Source mappings: 

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: 

Remaining discrepancies:
- Exact official tokenizer targets tpi, ty, rar, niu and gil are absent. No substitute model, alias or cloud fallback is approved or silently introduced. Other required languages also need full Ask integration and appropriate quality/layout verification.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-437 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Verify clinical meaning and safety-language preservation.

Original reference: Part 9 / 9E. Saved content and verification / 437

Source mappings: TranslationInvestigation/madlad-candle-probe/src/main.rs; Tools/repack_madlad_for_llama.py; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift; FruitfolioTests/TranslationPreservationTests.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/MADLAD/candle-original-paragraph.stdout.json; Fruitfolio_Verification_Evidence/MADLAD/RESULT.md; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Delivery/LatestAppleTestResults.json; Fruitfolio_Verification_Evidence/MADLAD/candle-original-paragraph.stdout.json; Fruitfolio_Verification_Evidence/MADLAD/RESULT.md; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md

Remaining discrepancies:
- Bounded fixture PASS does not verify general clinical entailment, all required languages, arbitrary safety statements, script distinction or device acceptance. Production Ask translation remains gated.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-438 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Verify citations remain unchanged.

Original reference: Part 9 / 9E. Saved content and verification / 438

Source mappings: TranslationInvestigation/madlad-candle-probe/src/main.rs; Tools/repack_madlad_for_llama.py; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift; FruitfolioTests/TranslationPreservationTests.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/MADLAD/candle-original-paragraph.stdout.json; Fruitfolio_Verification_Evidence/MADLAD/RESULT.md; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Delivery/LatestAppleTestResults.json; Fruitfolio_Verification_Evidence/MADLAD/candle-original-paragraph.stdout.json; Fruitfolio_Verification_Evidence/MADLAD/RESULT.md; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md

Remaining discrepancies:
- Bounded fixture PASS does not verify general clinical entailment, all required languages, arbitrary safety statements, script distinction or device acceptance. Production Ask translation remains gated.
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.

## FF1B-439 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Verify offline inference.

Original reference: Part 9 / 9E. Saved content and verification / 439

Source mappings: Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/xcode-offline-madlad-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/xcode-offline-madlad-test.log

Remaining discrepancies:
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.

## FF1B-440 — PARTIAL

Verify language persistence after restarting the app.

Original reference: Part 9 / 9E. Saved content and verification / 440

Source mappings: Fruitfolio/Core/AppArchitecture/SettingsStore.swift; Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift; Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift; Fruitfolio/Privacy Settings/Prompt12SettingsView.swift; FruitfolioTests/LanguagePreferencePersistenceTests.swift; FruitfolioUITests/LanguageSelectionJourneyUITests.swift; Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift; FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Delivery/LatestAppleTestResults.json; Delivery/SOURCE91_EXPORT_AND_EXPLICIT_LANGUAGE_COVERAGE.md

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Complete medically reviewed app-wide localization and exact selected-language UI verification; added 15-language runtime coverage and persistence/restart evidence pending. Five required official target tags remain absent; no substitute model or tag is used.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-441 — EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Verify the actual MADLAD runtime executes locally.

Original reference: Part 9 / 9E. Saved content and verification / 441

Source mappings: 

Source-sprint records: 

Current verification: EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT

Evidence: Fruitfolio_Verification_Evidence/AppleRuns/Run35/MADLAD_ActualAppleRuntime.txt; Fruitfolio_Verification_Evidence/AppleRuns/Run35/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run35/MADLAD_ActualAppleRuntime.txt; Fruitfolio_Verification_Evidence/AppleRuns/Run35/UnitBuild/xcode-unit-test.log

Remaining discrepancies:
- MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.

## FF1B-442 — NOT VERIFIED

Test layout and accessibility for each supported writing system.

Original reference: Part 9 / 9E. Saved content and verification / 442

Source mappings: 

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: 

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-443 — NOT VERIFIED

Create tests for every applicable Prompt 1B change.

Original reference: Part 10 / Testing, integration, and final verification / 443

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-444 — IMPLEMENTED — VERIFICATION PENDING

Add tests to the project’s source rather than relying only on an external checklist.

Original reference: Part 10 / Testing, integration, and final verification / 444

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-445 — NOT VERIFIED

Test the shared blur system.

Original reference: Part 10 / Testing, integration, and final verification / 445

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-446 — NOT VERIFIED

Test button animation and sound consistency.

Original reference: Part 10 / Testing, integration, and final verification / 446

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-447 — NOT VERIFIED

Test popup text fitting and character placement.

Original reference: Part 10 / Testing, integration, and final verification / 447

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-448 — NOT VERIFIED

Test decorative artwork responsiveness.

Original reference: Part 10 / Testing, integration, and final verification / 448

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-449 — NOT VERIFIED

Test semantic styling across normal and fallback responses.

Original reference: Part 10 / Testing, integration, and final verification / 449

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-450 — NOT VERIFIED

Test intro timing, interruption, and reduced-motion behavior.

Original reference: Part 10 / Testing, integration, and final verification / 450

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-451 — NOT VERIFIED

Test Hub tour highlights on different screen sizes.

Original reference: Part 10 / Testing, integration, and final verification / 451

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-452 — NOT VERIFIED

Test Ask continuous scrolling and session-only history.

Original reference: Part 10 / Testing, integration, and final verification / 452

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-453 — NOT VERIFIED

Test successful and canceled Guide saves.

Original reference: Part 10 / Testing, integration, and final verification / 453

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-454 — PARTIAL

Test Ask evidence grounding, citations, and fallback behavior.

Original reference: Part 10 / Testing, integration, and final verification / 454

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run17/Unit/xcode-unit-test.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run17/Unit/xcode-unit-test.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-455 — PARTIAL

Test encyclopedia creation, editing, image import, and deletion.

Original reference: Part 10 / Testing, integration, and final verification / 455

Source mappings: .github/workflows/ios-verification.yml; FruitfolioUITests/UserAuthoredPageUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UserPages/Build/xcode-user-pages-ui-test.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UserPages/Build/xcode-user-pages-ui-test.log

Remaining discrepancies:
- Full encyclopedia rename/recolour/delete, all alternate file/import and error states, and the new continuous book behavior still need dedicated verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-456 — NOT VERIFIED

Test continuous book-opening behavior.

Original reference: Part 10 / Testing, integration, and final verification / 456

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-457 — NOT VERIFIED

Test Guide synchronization between features.

Original reference: Part 10 / Testing, integration, and final verification / 457

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-458 — PARTIAL

Test Hormone Information creation, editing, deletion, and persistence.

Original reference: Part 10 / Testing, integration, and final verification / 458

Source mappings: FruitfolioTests/HormoneMeasurementTests.swift; FruitfolioUITests/HormoneMeasurementUITests.swift; Fruitfolio/Hormone Information/HormoneInformationView.swift

Source-sprint records: Delivery/FiveHour_Phase3_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run41/Build/xcode-hormone-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run41/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run41/Build/xcode-hormone-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run41/Visual/HormoneInformation/manifest.json; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md

Remaining discrepancies:
- Retrieve actual current-source deletion guard and complete lifecycle UI results; do not infer them from older native-dialog acceptance.
- Actual simulator execution, strict audits and chart/accessibility acceptance remain pending.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-459 — NOT VERIFIED

Test educational Hormone Rhythm separation.

Original reference: Part 10 / Testing, integration, and final verification / 459

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-460 — NOT VERIFIED

Test My Context adaptation and prediction safeguards.

Original reference: Part 10 / Testing, integration, and final verification / 460

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-461 — NOT VERIFIED

Test Cycle Tracker interactions and unified symptom trends.

Original reference: Part 10 / Testing, integration, and final verification / 461

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Rerun relevant actual UI tests after repairs; full integrated acceptance remains failed/unverified.
- Rerun the original strict failing journeys against the delivered source. Historical failed results remain open until actual passing evidence exists.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-462 — PARTIAL

Test Fruit Basket star passes, physics, weather, and progression.

Original reference: Part 10 / Testing, integration, and final verification / 462

Source mappings: .github/workflows/ios-verification.yml; Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioTests/FruitBasketGroundedResearchTests.swift; FruitfolioUITests/FruitBasketGroundedJourneyUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Delivery/SOURCE89_GROUNDED_GAME_AND_ACCESSIBILITY.md; Delivery/SOURCE90_GAME_JOURNEY_AND_TRANSLATION_REGRESSIONS.md; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Retrieve current Apple repair-batch and focused gameplay evidence; finish exact visual/semantic/difficulty acceptance. Deterministic quote fallback is bounded, not full AI educational-generation acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-463 — IMPLEMENTED — VERIFICATION PENDING

Test username synchronization.

Original reference: Part 10 / Testing, integration, and final verification / 463

Source mappings: .github/workflows/ios-verification.yml; Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift; Fruitfolio/Privacy Settings/Prompt12AccountView.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift; FruitfolioUITests/UsernameSynchronizationUITests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/USERNAME_EDITING_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UsernameJourney/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UsernameJourney/Build/xcode-username-journey-ui-test.log; Delivery/RUN46_RUNTIME_DIAGNOSTIC_REPAIRS.md; Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log; Delivery/USERNAME_EDITING_REPAIR.md; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UsernameJourney/Build/xcode-username-journey-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run46/UsernameJourney/Build/xcode-username-journey-ui-test.log; Delivery/RUN46_RUNTIME_DIAGNOSTIC_REPAIRS.md; Fruitfolio_Verification_Evidence/AppleRuns/Run64/Username/Build/xcode-username-journey-ui-test.log

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-464 — NOT VERIFIED

Test FAQ and Contact artwork.

Original reference: Part 10 / Testing, integration, and final verification / 464

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-465 — PARTIAL

Test audio preferences and global mute.

Original reference: Part 10 / Testing, integration, and final verification / 465

Source mappings: .github/workflows/ios-verification.yml; Fruitfolio/Core/Assets/AudioManager.swift; FruitfolioUITests/SettingsVolumeUITests.swift; FruitfolioTests/AudioLifecycleRuntimeTests.swift

Source-sprint records: Delivery/FiveHour_Phase2_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run50/Volumes/Build/xcode-settings-volumes-ui-test.log; Delivery/RUN50_VOLUME_NAVIGATION_DIAGNOSTIC.md; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run50/Volumes/Build/xcode-settings-volumes-ui-test.log; Delivery/RUN50_VOLUME_NAVIGATION_DIAGNOSTIC.md

Remaining discrepancies:
- Actual Run50 native music-slider value remained unchanged after synthesized drag. Bidirectional complete-viewport test-helper correction requires actual rerun; later category/master/restart steps were not reached.
- Founder Mac execution, real interruptions and audible output/quality still require verification; these source changes do not constitute complete requirement acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-466 — PARTIAL

Test localization and offline MADLAD integration when that phase is implemented.

Original reference: Part 10 / Testing, integration, and final verification / 466

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/Offline/MADLAD/Offline/actual-offline-verification.json

Remaining discrepancies:
- Complete and verify app-wide localization and required-language integration.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-467 — IMPLEMENTED — VERIFICATION PENDING

Run relevant unit tests.

Original reference: Part 10 / Testing, integration, and final verification / 467

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run17/Unit/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run17/Unit/xcode-unit-test.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/RUN61_VERIFICATION.md

Remaining discrepancies:
- Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-468 — NOT VERIFIED

Run UI tests.

Original reference: Part 10 / Testing, integration, and final verification / 468

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Delivery/LatestAppleTestResults.json; Delivery/RUN92_VERIFICATION_AND_REPAIRS.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Rerun relevant actual UI tests after repairs; full integrated acceptance remains failed/unverified.
- Rerun the original strict failing journeys against the delivered source. Historical failed results remain open until actual passing evidence exists.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-469 — NOT VERIFIED

Capture screenshots of all affected screens and meaningful nested states.

Original reference: Part 10 / Testing, integration, and final verification / 469

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-470 — NOT VERIFIED

Inspect visual layouts for clipping, collisions, duplication, and misalignment.

Original reference: Part 10 / Testing, integration, and final verification / 470

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-471 — NOT VERIFIED

Test accessibility, including VoiceOver and Dynamic Type.

Original reference: Part 10 / Testing, integration, and final verification / 471

Source mappings: .github/workflows/ios-verification.yml; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Delivery/LatestAppleTestResults.json; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Delivery/RUN92_VERIFICATION_AND_REPAIRS.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Rerun relevant actual UI tests after repairs; full integrated acceptance remains failed/unverified.
- Rerun the original strict failing journeys against the delivered source. Historical failed results remain open until actual passing evidence exists.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-472 — PARTIAL

Test Reduce Motion.

Original reference: Part 10 / Testing, integration, and final verification / 472

Source mappings: .github/workflows/ios-verification.yml; Fruitfolio/Ask/Prompt09AskViewModel.swift; Fruitfolio/Ask/Prompt09AskView.swift

Source-sprint records: Delivery/FiveHour_Phase4_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Actual live system changes, UI recordings and audio stop on founder Mac/device; other screens require independent verification.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-473 — PARTIAL

Test app backgrounding and foregrounding.

Original reference: Part 10 / Testing, integration, and final verification / 473

Source mappings: .github/workflows/ios-verification.yml; Fruitfolio/Core/Assets/AudioManager.swift

Source-sprint records: Delivery/FiveHour_Phase7_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/actual-ui-results.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run45/actual-ui-results.json

Remaining discrepancies:
- New nested editor/language/translation lifecycle states still require their own verification.
- Execute on Mac; real device interruptions, route changes and listening quality remain unverified.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-474 — PARTIAL

Test persistence and data deletion.

Original reference: Part 10 / Testing, integration, and final verification / 474

Source mappings: .github/workflows/ios-verification.yml; Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift; Fruitfolio/Global Controls/Prompt08GlobalControls.swift; Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift; FruitfolioUITests/ModalScrollSupport.swift; FruitfolioUITests/PersonalDataManagementUITests.swift; FruitfolioTests/NativeActionLabelRuntimeTests.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift; Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift

Source-sprint records: Delivery/FiveHour_Phase7_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/PERSONAL_DATA_EXPORT_IMPLEMENTATION.md; Delivery/CYCLE_ERASE_FAILURE_SAFETY.md; Delivery/SOURCE94_GUARDED_MODAL_FIT_AND_REACH.md; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/AppleRuns/Run61/UnitBuild/xcode-unit-test.log; Delivery/PERSONAL_DATA_EXPORT_IMPLEMENTATION.md; Delivery/CYCLE_ERASE_FAILURE_SAFETY.md

Remaining discrepancies:
- Actual system export/save/cancel UI, full cross-domain deletion coordinators and exhaustive restart/privacy/device verification remain unfinished.
- Run full gameplay/persistence/UI regressions and process-restart journeys on founder Mac; source fixtures do not establish physical-device kill durability.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-475 — NOT VERIFIED

Test app performance and responsiveness.

Original reference: Part 10 / Testing, integration, and final verification / 475

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-476 — PARTIAL

Produce logs and evidence for completed corrections.

Original reference: Part 10 / Testing, integration, and final verification / 476

Source mappings: .github/workflows/ios-verification.yml; Tools/verify_integrated_source_on_mac.py; Tools/reconcile_five_hour_tracker.py; Tools/package_final_delivery.py

Source-sprint records: Delivery/FiveHour_Phase8_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Run actual integrated Mac build/test/visual/accessibility/device verification. Do not treat structural checks or proposed tracker counts as full application acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-477 — IMPLEMENTED — VERIFICATION PENDING

Identify remaining failures rather than declaring unverified requirements complete.

Original reference: Part 10 / Testing, integration, and final verification / 477

Source mappings: .github/workflows/ios-verification.yml; Tools/verify_integrated_source_on_mac.py; Tools/reconcile_five_hour_tracker.py; Tools/package_final_delivery.py

Source-sprint records: Delivery/FiveHour_Phase8_RequirementChanges.json

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Item-level checkpoint assessment and requirement-specific runtime verification pending.
- Run13: 26 broad UI tests, 13 failures. Run14: normal-motion launch timed out, focused functional tests skipped. Neither run is an overall pass.
- Run actual integrated Mac build/test/visual/accessibility/device verification. Do not treat structural checks or proposed tracker counts as full application acceptance.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

## FF1B-478 — NOT VERIFIED

Run the full integrated test suite after combining the corrected parts.

Original reference: Part 10 / Testing, integration, and final verification / 478

Source mappings: .github/workflows/ios-verification.yml

Source-sprint records: 

Current verification: NOT VERIFIED for delivered integrated source

Evidence: Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log; Delivery/LatestAppleTestResults.json; Delivery/RUN92_VERIFICATION_AND_REPAIRS.json; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run13/complete-job.log; Fruitfolio_Verification_Evidence/Continuation/AppleRuns/Run14/complete-job.log

Remaining discrepancies:
- Rerun relevant actual UI tests after repairs; full integrated acceptance remains failed/unverified.
- Rerun the original strict failing journeys against the delivered source. Historical failed results remain open until actual passing evidence exists.
- Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.

