import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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

    // Injectable so the DEBUG route never exports the real user's storage.
    var exportPreferences: () throws -> [FruitfolioLocalDataExport.PreferenceRecord] = {
        try FruitfolioLocalDataExport.capturePreferences(defaults: .standard)
    }
    var exportApplicationSupport: URL? = nil
    @State private var exportTask: Task<Void, Never>?
    @State private var exportMessage: String?
    @State private var exportFolder: URL?
    @State private var exportDocument: ExportDocument?
    @State private var exportGeneration = UUID()
    private struct ExportDocument: Identifiable {
        let id = UUID()
        let result: FruitfolioLocalDataExport.Result
    }

    @State private var didOpenPopup = false
    @State private var popupClosing = false
    @AccessibilityFocusState private var popupHeadingFocused: Bool
    @State private var showingMeasurements = false
    @State private var showLocalDeletionNotice = false

    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .onDisappear {
                exportGeneration = UUID()
                exportTask?.cancel()
                exportTask = nil
                if exportDocument == nil { cleanExportFolder() }
            }
            #if canImport(UIKit)
            .sheet(item: $exportDocument, onDismiss: {
                if exportMessage == nil { exportMessage = "export cancelled. your saved data has not changed." }
                cleanExportFolder()
            }) { document in
                FruitfolioDataExportPicker(url: document.result.url) { saved in
                    exportMessage = saved
                        ? (document.result.warnings.isEmpty ? "your local data export was saved." : "your local data export was saved with missing or unreadable items. see manifest.json for details.")
                        : "export cancelled. your saved data has not changed."
                    exportDocument = nil
                }
            }
            #endif
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
                    .accessibilityElement(children: .contain)
                    .accessibilityAddTraits(.isModal)
                    .accessibilityAction(.escape) { dismissPopup() }
                    .task {
                        guard !didOpenPopup else { return }
                        didOpenPopup = true
                        #if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil)
                        #endif
                        audioManager.play(.popupOpen)
                        await Task.yield()
                        guard !Task.isCancelled, !popupClosing else { return }
                        popupHeadingFocused = true
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
                        "manage your saved information",
                    assetName:
                        "ask_source_pages",
                    onBack:
                        onBack
                )
            } else {
                FruitfolioTranslatedText(source: "data",
                    font: .custom("Chalkboard SE", size: 18, relativeTo: .headline),
                    color: DesignTokens.ColorToken.primaryBurgundy)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($popupHeadingFocused)
                    .accessibilityIdentifier("dataManagement.heading")

                Image("ask_source_pages")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54)
                    .accessibilityHidden(true)
            }

            Prompt12SavedRecordNotice(store: store)
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
                    dismissPopup()
                }
                .accessibilityIdentifier("dataManagement.close")
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
    }

    @discardableResult
    private func dismissPopup() -> Bool {
        // A presented child owns its own dismissal; Escape cannot close the
        // underlying data panel or leave an active document picker behind.
        guard mode == .popup, !popupClosing, !showingMeasurements, exportDocument == nil else { return false }
        popupClosing = true
        popupHeadingFocused = false
        audioManager.play(.popupClose)
        onBack()
        return true
    }

    private var exportCard: some View {
        dataSection {
            cardTitle(
                "available exports"
            )

            centeredInfoText("export your saved books, guides, notes, referenced images, measurements, My Context, cycle records, local account state, username, game progress and app preferences. the ZIP contains private information and is not encrypted. choose a private place to keep it. unsaved Ask conversations and cloud-only data are not included.")

            FruitfolioControlPillButton(label: "export saved local data") { beginLocalExport() }
                .disabled(exportTask != nil)
                .accessibilityIdentifier("dataManagement.localExport")
            if exportTask != nil {
                ProgressView("preparing your local data export…")
                WatercolorSecondaryButton(label: "cancel export") { exportTask?.cancel() }
                    .accessibilityIdentifier("dataManagement.cancelExport")
            }
            if let exportMessage { centeredInfoText(exportMessage) }

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

    private func beginLocalExport() {
        guard exportTask == nil else { return }
        exportMessage = nil
        exportGeneration = UUID()
        let generation = exportGeneration
        do {
            let records = try exportPreferences()
            guard let support = exportApplicationSupport ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw FruitfolioZIPArchive.Failure.invalidSource
            }
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("FruitfolioExport-" + UUID().uuidString)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,
                                                    attributes: [.posixPermissions: 0o700])
            exportFolder = folder
            let output = folder.appendingPathComponent("Fruitfolio-Local-Data.zip")
            exportTask = Task {
                let worker = Task.detached(priority: .userInitiated) {
                    try FruitfolioLocalDataExport.create(preferences: records, applicationSupport: support, output: output)
                }
                do {
                    let result = try await withTaskCancellationHandler(operation: { try await worker.value },
                                                                       onCancel: { worker.cancel() })
                    try Task.checkCancellation()
                    guard exportGeneration == generation else {
                        try? FileManager.default.removeItem(at: folder)
                        return
                    }
                    exportTask = nil
                    #if canImport(UIKit)
                    exportDocument = ExportDocument(result: result)
                    #else
                    exportMessage = "saving local exports requires the iOS document picker."
                    cleanExportFolder()
                    #endif
                } catch {
                    try? FileManager.default.removeItem(at: folder)
                    guard exportGeneration == generation else { return }
                    exportTask = nil
                    exportFolder = nil
                    exportMessage = error is CancellationError
                        ? "export cancelled. your saved data has not changed."
                        : "the local export could not be prepared. your saved data has not changed."
                }
            }
        } catch {
            cleanExportFolder()
            exportMessage = "the local export could not be prepared. your saved data has not changed."
        }
    }

    private func cleanExportFolder() {
        if let folder = exportFolder { try? FileManager.default.removeItem(at: folder) }
        exportFolder = nil
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
                    if mode == .popup, !dismissPopup() { return }
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
        if mode == .popup {
            guard dismissPopup() else { return }
        } else { onBack() }
        navigation.navigate(to: route)
    }
}
