import SwiftUI
import UniformTypeIdentifiers

enum Prompt12DataManagementMode: Equatable {
    case fullPage
    case popup
}

struct Prompt12DataManagementView: View {
    @ObservedObject var store: Prompt12AccountPrivacyStore

    let mode: Prompt12DataManagementMode
    let onBack: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var contextStore: Prompt27AContextStore
    @EnvironmentObject private var motion: MotionPreferences
    @State private var exportDocument: FruitfolioPersonalDataDocument?
    @State private var showingExportDestination = false
    @State private var preparingExport = false

    @State private var confirmHormoneErase = false
    @State private var message: String?
    @State private var showLocalDeletionNotice = false

    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .fruitfolioModalBlur(active: confirmHormoneErase, reduceMotion: motion.reduceMotionActive)
            .overlay {
                if confirmHormoneErase {
                    Prompt12ConfirmationPopup(assetName: "popup_warning", title: "delete all hormone measurements?",
                        message: "this removes hormone results only. cycle logs, saved guides, and account information are unchanged.",
                        primaryLabel: "cancel", secondaryLabel: nil, destructiveLabel: "delete hormone measurements",
                        primaryAction: { confirmHormoneErase = false }, secondaryAction: nil,
                        destructiveAction: {
                            do {
                                try HormoneMeasurementStore.shared.eraseAll()
                                message = "hormone measurements have been deleted from this device."
                            } catch { message = error.localizedDescription }
                            confirmHormoneErase = false
                        })
                }
            }
            .fileExporter(isPresented: $showingExportDestination, document: exportDocument,
                          contentType: .json, defaultFilename: "Fruitfolio-Personal-Data") { result in
                switch result {
                case .success: message = "your personal data JSON was exported. keep it somewhere private."
                case .failure(let error): message = error.localizedDescription
                }
                exportDocument = nil
            }
    }

    private var content: some View {
        Group {
            if mode == .popup {
                GeometryReader { proxy in
                    ScrollView {
                        innerContent
                            .padding(.horizontal, 16)
                            .padding(.vertical, 24)
                    }
                    .scrollIndicators(.hidden)
                    .frame(
                        width: min(
                            350,
                            max(
                                280,
                                proxy.size.width - 32
                            )
                        )
                    )
                    .frame(
                        maxHeight: max(
                            320,
                            min(
                                720,
                                proxy.size.height - 36
                            )
                        )
                    )
                    .background {
                        RoundedRectangle(
                            cornerRadius: 32,
                            style: .continuous
                        )
                        .fill(
                            DesignTokens
                                .ColorToken
                                .backgroundCream
                                .opacity(0.985)
                        )
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: 32,
                                style: .continuous
                            )
                            .stroke(
                                DesignTokens
                                    .ColorToken
                                    .primaryBurgundy
                                    .opacity(0.18),
                                lineWidth: 1
                            )
                        }
                        .shadow(
                            color:
                                Color.black
                                    .opacity(0.08),
                            radius: 12,
                            x: 0,
                            y: 5
                        )
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .center
                    )
                }
                .onAppear {
                    audioManager.play(.popupOpen)
                }
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
                        "export and manage supported Fruitfolio data",
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
            FruitfolioControlPillButton(label: "delete local hormone measurements") {
                confirmHormoneErase = true
            }
            .accessibilityIdentifier("data.deleteHormones")

            if let message {
                Text(message)
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 11
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
                        maxWidth: 290,
                        alignment: .center
                    )
            }

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
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
    }

    private var exportCard: some View {
        FruitfolioLargeCard {
            cardTitle(
                "export my data"
            )

            centeredInfoText(
                "export readable JSON of your account, saved encyclopedia and guide text, source references, settings, cycle records, reported context, hormone results, and Fruit Basket progress. this file contains sensitive health data. choose a private destination. original imported image files and session-only Ask conversations are not included; this is not a complete media backup."
            )

            FruitfolioControlPillButton(
                label: preparingExport ? "preparing your export…" : "prepare export"
            ) {
                prepareExport()
            }
            .disabled(preparingExport)
            .accessibilityIdentifier("data.prepareExport")
            .frame(
                maxWidth: 260,
                alignment: .center
            )
        }
    }

    private var includedAreasCard: some View {
        FruitfolioLargeCard {
            cardTitle(
                "included areas"
            )

            VStack(
                alignment: .center,
                spacing: 13
            ) {
                ForEach(
                    Prompt12DataScope
                        .allCases
                ) { scope in
                    VStack(
                        alignment: .center,
                        spacing: 3
                    ) {
                        Text(scope.title)
                            .font(
                                .custom(
                                    "Chalkboard SE",
                                    size: 11.5
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

                        Text(scope.detail)
                            .font(
                                .custom(
                                    "Chalkboard SE",
                                    size: 10
                                )
                            )
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
        FruitfolioLargeCard {
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
                "destructive actions must explain exactly what disappears. cycle-data erasure must also invalidate dependent calculations, estimates, predictions, and insights so stale derived state is never left behind."
            )

            FruitfolioControlPillButton(
                label: "review deletion options"
            ) {
                showLocalDeletionNotice = true
            }
            .frame(
                maxWidth: 260,
                alignment: .center
            )
        }
    }

    private var localDeletionNoticeCard: some View {
        FruitfolioLargeCard {
            cardTitle(
                "not deleted yet",
                size: 13
            )

            centeredInfoText(
                "this phase defines the safe architecture. it does not erase unrelated domains until their deletion coordinators exist."
            )
        }
    }

    private func cardTitle(
        _ text: String,
        size: CGFloat = 15
    ) -> some View {
        Text(text)
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
        Prompt12InfoText(text)
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

    private func prepareExport() {
        guard !preparingExport else { return }
        preparingExport = true
        message = nil
        Task { @MainActor in
            defer { preparingExport = false }
            do {
                let data = try await FruitfolioPersonalDataExport.capture(account: store.account,
                    username: FruitfolioUsernameStore.shared.username, settings: settings,
                    library: .shared, context: contextStore, hormones: .shared)
                _ = try store.prepareDataExport()
                exportDocument = FruitfolioPersonalDataDocument(data: data)
                showingExportDestination = true
                message = "your readable JSON is prepared. choose where to save it; nothing is sent automatically."
            } catch {
                exportDocument = nil
                message = error.localizedDescription
            }
        }
    }
}
