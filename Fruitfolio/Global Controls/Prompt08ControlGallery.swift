import SwiftUI

/// Development-only visual QA surface for Prompt 08.
/// The audio toggles below are intentionally bound to the real shared SettingsStore
/// so this gallery tests actual application behavior instead of cosmetic local state.
#if DEBUG
struct Prompt08ControlGallery: View {

    @State
    private var selectedChoice: String? =
        "first"

    @State
    private var bookmarkSaved = false

    @EnvironmentObject
    private var settings: SettingsStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                Text("global controls")
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 24,
                            relativeTo: .title2
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens
                            .ColorToken
                            .primaryBurgundy
                    )

                WatercolorPrimaryButton(
                    label: "continue"
                ) {}

                WatercolorSecondaryButton(
                    label: "maybe later"
                ) {}

                HStack(spacing: 20) {
                    BackControl {}

                    CloseControl {}

                    AddControl {}

                    ConfirmControl {}

                    BookmarkButton(
                        isBookmarked:
                            $bookmarkSaved
                    )
                }

                Button {
                    selectedChoice = "first"

                } label: {
                    HStack(spacing: 10) {
                        ChoiceCircle(
                            isSelected:
                                selectedChoice
                                    == "first"
                        )

                        Text(
                            "example choice"
                        )
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 14,
                                relativeTo:
                                    .body
                            )
                        )
                        .foregroundStyle(
                            DesignTokens
                                .ColorToken
                                .primaryBurgundy
                        )

                        Spacer()
                    }
                    .frame(
                        minHeight:
                            DesignTokens
                                .Layout
                                .minimumHitTarget
                    )
                    .contentShape(
                        Rectangle()
                    )
                }
                .buttonStyle(.plain)

                VStack(spacing: 14) {

                    WatercolorToggle(
                        label: "music",
                        isOn:
                            $settings
                                .musicEnabled
                    )

                    WatercolorToggle(
                        label:
                            "rain ambience",
                        isOn:
                            $settings
                                .rainEnabled
                    )

                    WatercolorToggle(
                        label:
                            "sound effects",
                        isOn:
                            $settings
                                .soundEffectsEnabled
                    )

                    WatercolorToggle(
                        label:
                            "typing ASMR",
                        isOn:
                            $settings
                                .typingASMREnabled
                    )
                }

                InfoTooltip(
                    message:
                        "these switches are connected to Fruitfolio's real audio settings."
                )

                WatercolorBottomSheet(
                    title:
                        "example sheet",
                    onClose: {}
                ) {
                    VStack(spacing: 14) {

                        Button {
                            selectedChoice =
                                "sheet"

                        } label: {
                            HStack(
                                spacing: 10
                            ) {
                                ChoiceCircle(
                                    isSelected:
                                        selectedChoice
                                            == "sheet"
                                )

                                Text(
                                    "sheet choice"
                                )
                                .font(
                                    .custom(
                                        "Chalkboard SE",
                                        size: 14,
                                        relativeTo:
                                            .body
                                    )
                                )
                                .foregroundStyle(
                                    DesignTokens
                                        .ColorToken
                                        .primaryBurgundy
                                )

                                Spacer()
                            }
                            .frame(
                                minHeight:
                                    DesignTokens
                                        .Layout
                                        .minimumHitTarget
                            )
                            .contentShape(
                                Rectangle()
                            )
                        }
                        .buttonStyle(.plain)

                        WatercolorPrimaryButton(
                            label: "done"
                        ) {}
                    }
                }
            }
            .padding(20)
        }
        .background(
            DesignTokens
                .ColorToken
                .backgroundCream
                .ignoresSafeArea()
        )
    }
}
#endif
