import SwiftUI

enum Prompt12DataManagementMode: Equatable {
    case fullPage
    case popup
}

struct Prompt12DataManagementView: View {
    @ObservedObject var store: Prompt12AccountPrivacyStore

    let mode: Prompt12DataManagementMode
    let onBack: () -> Void
    var onShowMyContext: (() -> Void)? = nil

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var navigation: NavigationCoordinator

    @State private var showingMeasurements = false
    @State private var showLocalDeletionNotice = false

    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingMeasurements) {
                FruitfolioPresentedPopupHost {
                    FruitfolioHormoneInformationView(onBack: { showingMeasurements = false })
                }
            }
    }

    private var content: some View {
        Group {
            if mode == .popup {
                FruitfolioTapedWhitePopup { innerContent.controlSize(.small) }
                    .accessibilityIdentifier("dataManagement.popup")
                    .onAppear { audioManager.play(.popupOpen) }
            } else {
                ZStack {
                    DesignTokens
                        .ColorToken
                        .backgroundCream
                        .ignoresSafeArea()

                    ScrollView {
                        innerContent
                            .padding(.horizontal, 20)
                            .padding(.bottom, 42)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
    }

    private var innerContent: some View {
        VStack(spacing: 16) {
            if mode == .fullPage {
                Prompt12RouteHeader(
                    title: "data",
                    subtitle:
                        "manage your saved information",
                    assetName:
                        "ask_source_pages",
                    onBack:
                        onBack
                )
            } else {
                Text("data")
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 18
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens
                            .ColorToken
                            .primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )

                Image("ask_source_pages")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54)
                    .accessibilityHidden(true)
            }

            exportCard
            includedAreasCard
            deletionCard

            if showLocalDeletionNotice {
                localDeletionNoticeCard
            }

            if mode == .popup {
                WatercolorSecondaryButton(
                    label: "close"
                ) {
                    audioManager.play(
                        .popupClose
                    )
                    onBack()
                }
                .accessibilityIdentifier("dataManagement.close")
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
    }

    private var exportCard: some View {
        dataSection {
            cardTitle(
                "available exports"
            )

            centeredInfoText(
                "open Hormone Information to export your measurements as a readable JSON file. choose where to keep the file; it contains the measurements you saved."
            )

            FruitfolioControlPillButton(
                label: "open measurement export"
            ) {
                showingMeasurements = true
            }
            .accessibilityIdentifier("dataManagement.measurementExport")
            .frame(
                maxWidth: 260,
                alignment: .center
            )
        }
    }

    private var includedAreasCard: some View {
        dataSection {
            cardTitle(
                "your saved information"
            )

            VStack(
                alignment: .center,
                spacing: 13
            ) {
                ForEach(
                    [Prompt12DataScope.savedLibrary, .guideBuilder, .settings, .cycleTracker]
                ) { scope in
                    VStack(
                        alignment: .center,
                        spacing: 3
                    ) {
                        Text(settings.localized(scope.title))
                            .font(
                                .custom(
                                    "Chalkboard SE",
                                    size: 13, relativeTo: .headline
                                )
                            )
                            .fontWeight(.bold)
                            .foregroundStyle(
                                DesignTokens
                                    .ColorToken
                                    .primaryBurgundy
                            )
                            .multilineTextAlignment(
                                .center
                            )
                            .lineLimit(nil)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .center
                            )

                        FruitfolioTranslatedText(source: scope.detail,
                            font: .custom("Chalkboard SE", size: 13, relativeTo: .body), serious: true)
                            .foregroundStyle(
                                DesignTokens
                                    .ColorToken
                                    .secondaryBurgundy
                            )
                            .multilineTextAlignment(
                                .center
                            )
                            .lineLimit(nil)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                            .frame(
                                maxWidth: 246,
                                alignment: .center
                            )
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )
                    .accessibilityElement(
                        children: .combine
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
        }
    }

    private var deletionCard: some View {
        dataSection {
            HStack(spacing: 6) {
                Image("popup_warning")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 22,
                        height: 22
                    )
                    .accessibilityHidden(true)

                Text("delete data")
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 15
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens
                            .ColorToken
                            .primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )

            centeredInfoText(
                "review the saved items in a feature before deleting them. books and their guide organization are managed together; cycle observations and hormone measurements have their own controls."
            )

            FruitfolioControlPillButton(
                label: "review deletion options"
            ) {
                showLocalDeletionNotice = true
            }
            .accessibilityIdentifier("dataManagement.reviewDeletion")
            .frame(
                maxWidth: 260,
                alignment: .center
            )
        }
    }

    private var localDeletionNoticeCard: some View {
        dataSection {
            cardTitle(
                "choose what to manage",
                size: 13
            )

            centeredInfoText(
                "open the feature that holds the information you want to review. nothing is deleted by opening these options. Ask conversations stay in their active session; saved answers and selections are managed with your books."
            )
            WatercolorSecondaryButton(label: "manage saved books") { open(.library) }
                .accessibilityIdentifier("dataManagement.books")
            WatercolorSecondaryButton(label: "manage guide organization") { open(.guideBuilder) }
            WatercolorSecondaryButton(label: "review cycle records") { open(.cycle) }
            WatercolorSecondaryButton(label: "manage hormone measurements") { showingMeasurements = true }
            if let onShowMyContext {
                WatercolorSecondaryButton(label: "review My Context") {
                    if mode == .popup { audioManager.play(.popupClose) }
                    onShowMyContext()
                }
            }
        }
    }

    private func cardTitle(
        _ text: String,
        size: CGFloat = 15
    ) -> some View {
        Text(settings.localized(text))
            .font(
                .custom(
                    "Chalkboard SE",
                    size: size
                )
            )
            .fontWeight(.bold)
            .foregroundStyle(
                DesignTokens
                    .ColorToken
                    .primaryBurgundy
            )
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
    }

    private func centeredInfoText(
        _ text: String
    ) -> some View {
        FruitfolioTranslatedText(source: text, protectedLiterals: ["JSON", "Fruitfolio"],
            font: .custom("Chalkboard SE", size: 13, relativeTo: .body), serious: true)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
    }

    @ViewBuilder
    private func dataSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if mode == .popup {
            VStack(spacing: 12) { content() }
        } else {
            FruitfolioLargeCard { content() }
        }
    }

    private func open(_ route: FruitfolioRoute) {
        if mode == .popup { audioManager.play(.popupClose) }
        onBack()
        navigation.navigate(to: route)
    }
}
