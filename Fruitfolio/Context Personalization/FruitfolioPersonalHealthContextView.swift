import SwiftUI
import UIKit

struct FruitfolioPersonalHealthContextView: View {
    @ObservedObject var store: Prompt27AContextStore
    let onBack: () -> Void
    @State private var editing: FruitfolioPersonalHealthCategory?
    @State private var viewIsVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    private var canInteract: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active && popupCoordinator.currentPopup == nil && editing == nil
    }
    @EnvironmentObject private var motionPreferences: MotionPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BackControl(action: { guard canInteract else { return }; onBack() })
                FruitfolioFixedText(source: "personal health context", font: .title2.bold(), serious: true).accessibilityAddTraits(.isHeader)
                FruitfolioTranslatedText(source: "entirely optional, user-provided context, stored on this device. explore only what matters to you. skip anything; no biological findings or diagnoses are guessed from your answers. these notes do not replace approved research or clinical advice.", serious: true)
                FruitfolioTranslatedText(source: "for laboratory artwork, choose a technique or sample category only if it was actually reported or you know it applies. otherwise use other labs / testing.", font: .callout, serious: true)
                    .font(.callout)
                FruitfolioContextStorageNotice(store: store)
                ForEach(FruitfolioPersonalHealthGroup.allCases) { group in
                    DisclosureGroup {
                        VStack(spacing: 12) {
                            ForEach(FruitfolioPersonalHealthCategory.allCases.filter { $0.group == group }) { category in
                                Button { guard canInteract else { return }; editing = category } label: {
                                    HStack(alignment: .center, spacing: 14) {
                                        if let asset = category.asset {
                                            FruitfolioImage(id: asset).scaledToFit().frame(width: 64, height: 64).allowsHitTesting(false).accessibilityHidden(true)
                                        }
                                        VStack(alignment: .leading, spacing: 5) {
                                            FruitfolioFixedText(source: category.title, protectedLiterals: category == .dna ? ["DNA"] : category == .rna ? ["RNA"] : [], serious: true).multilineTextAlignment(.leading)
                                            FruitfolioFixedText(source: status(category), font: .caption, serious: true)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(minHeight: 64)
                                }
                                .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                                .disabled(store.storageProtectionReason != nil)
                                .accessibilityIdentifier("personalHealth.category." + category.rawValue)
                                .accessibilityElement(children: .combine)
                            }
                        }
                        .padding(.vertical, 12)
                    } label: {
                        FruitfolioFixedText(source: group.title, font: .headline, serious: true).frame(minHeight: 44)
                    }
                }
            }
            .padding(20).frame(maxWidth: 680, alignment: .leading).frame(maxWidth: .infinity)
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .onAppear { viewIsVisible = true }
        .onDisappear { viewIsVisible = false }
        .sheet(item: $editing) { category in
            FruitfolioPresentedPopupHost {
                FruitfolioPersonalHealthEntryEditor(store: store, category: category, onClose: { editing = nil })
            }
        }
    }
    private func status(_ category: FruitfolioPersonalHealthCategory) -> String {
        switch store.context.personalHealthEntries[category.rawValue]?.status {
        case .provided: return "saved user-provided context · edit"
        case .preferNotToSay: return "prefer not to say · change"
        case .removed: return "removed · add again"
        case nil: return "optional · add or skip"
        }
    }
}

private struct FruitfolioPersonalHealthEntryEditor: View {
    @ObservedObject var store: Prompt27AContextStore
    let category: FruitfolioPersonalHealthCategory
    let onClose: () -> Void
    @State private var text: String
    @State private var clinicianConfirmed: Bool
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var viewIsVisible = false
    @Environment(\.scenePhase) private var scenePhase
    private var ownerIsActive: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
    }
    private var canInteract: Bool { ownerIsActive && popupCoordinator.currentPopup == nil }
    @State private var pendingAction: PendingAction?
    @State private var returnCloseFocus = false
    @State private var popupInstanceID = UUID()
    @AccessibilityFocusState private var closeFocused: Bool
    @AccessibilityFocusState private var errorFocused: Bool
    @State private var errorFocusRequest = UUID()
    @FocusState private var textFocused: Bool
    private enum PendingAction { case save, discard, remove }
    @State private var errorMessage: String?
    @State private var baselineText: String
    @State private var baselineConfirmation: Bool
    @State private var baselineRevision: UUID

    init(store: Prompt27AContextStore, category: FruitfolioPersonalHealthCategory, onClose: @escaping () -> Void) {
        self.store = store; self.category = category; self.onClose = onClose
        let record = store.context.personalHealthEntries[category.rawValue]
        let initial = record?.status == .provided ? (record?.text ?? "") : ""
        let confirmed = record?.status == .provided && record?.provenance == .userReportsClinicianConfirmed
        _baselineText = State(initialValue: initial)
        _baselineConfirmation = State(initialValue: confirmed)
        _baselineRevision = State(initialValue: store.savedRecordRevision)
        _text = State(initialValue: initial); _clinicianConfirmed = State(initialValue: confirmed)
    }
    private var changed: Bool { text != baselineText || clinicianConfirmed != baselineConfirmation }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FruitfolioFixedText(source: category.title, protectedLiterals: category == .dna ? ["DNA"] : category == .rna ? ["RNA"] : [], font: .title2.bold(), serious: true).accessibilityAddTraits(.isHeader)
                if let asset = category.asset {
                    FruitfolioImage(id: asset).scaledToFit().frame(maxWidth: 100, maxHeight: 100).allowsHitTesting(false).accessibilityHidden(true)
                }
                FruitfolioTranslatedText(source: "anything you want Fruitfolio to know? this is your report, not something Fruitfolio has verified.", serious: true)
                TextEditor(text: $text).frame(minHeight: 180).accessibilityLabel("optional personal health context")
                    .accessibilityIdentifier("personalHealth.editor.text")
                    .focused($textFocused)
                Text("\(text.count) / 10000 characters").font(.caption)
                Toggle(isOn: $clinicianConfirmed) { FruitfolioFixedText(source: "a clinician confirmed this information, as i report it", serious: true) }
                if category.group == .genetics {
                    FruitfolioTranslatedText(source: "record only findings or history you choose to supply. Fruitfolio will not infer a genotype, inheritance pattern, disease risk or diagnosis.", font: .callout, serious: true).font(.callout)
                }
                if category == .knownOvulation {
                    FruitfolioTranslatedText(source: "this remains user-reported history. it does not confirm ovulation or replace Cycle Tracker’s separately labeled estimates.", font: .callout, serious: true).font(.callout)
                }
                FruitfolioContextStorageNotice(store: store)
                if let errorMessage {
                    FruitfolioTranslatedContent(source: errorMessage) { display, _ in
                        FruitfolioSemanticText(markdown: display,
                            baseFont: .custom("Chalkboard SE", size: 14, relativeTo: .body), serious: true)
                            .accessibilityFocused($errorFocused)
                    }
                    .task(id: errorFocusRequest) {
                        await Task.yield()
                        guard !Task.isCancelled, ownerIsActive else { return }
                        errorFocused = true
                    }
                }
                WatercolorPrimaryButton(label: "save my context") { guard canInteract else { return }; save(status: .provided) }
                    .disabled(store.storageProtectionReason != nil)
                WatercolorSecondaryButton(label: "prefer not to say") { guard canInteract else { return }; save(status: .preferNotToSay) }
                    .disabled(store.storageProtectionReason != nil)
                if store.context.personalHealthEntries[category.rawValue]?.isActive == true {
                    WatercolorSecondaryButton(label: "remove this context") { requestConfirmation(removal: true) }
                        .accessibilityIdentifier("personalHealth.editor.remove")
                        .disabled(store.storageProtectionReason != nil)
                }
                WatercolorSecondaryButton(label: "skip / close") {
                    guard canInteract else { return }
                    if changed { requestConfirmation(removal: false) } else { onClose() }
                }
                .accessibilityIdentifier("personalHealth.editor.close")
                .accessibilityFocused($closeFocused)
            }
            .padding(20).frame(maxWidth: 680, alignment: .leading).frame(maxWidth: .infinity)
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .accessibilityIdentifier("personalHealth.editor.scroll")
        .interactiveDismissDisabled(changed)
        .onAppear {
            viewIsVisible = true
            if popupOwner == nil { popupOwner = FruitfolioOwnedPopupSession(coordinator: popupCoordinator) }
        }
        .onDisappear {
            viewIsVisible = false
            popupOwner?.cancel()
            pendingAction = nil
            returnCloseFocus = false
        }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            popupOwner?.observeDismissal()
            guard viewIsVisible, popupOwner?.requestID == nil, popupCoordinator.currentPopup == nil else { return }
            let action = pendingAction
            pendingAction = nil
            switch action {
            case .save: save(status: .provided)
            case .remove: save(status: .removed)
            case .discard: onClose()
            case nil: break
            }
            if returnCloseFocus { returnCloseFocus = false; closeFocused = true }
        }
    }

    private func requestConfirmation(removal: Bool) {
        guard canInteract, let owner = popupOwner else { return }
        returnCloseFocus = true
        closeFocused = false
        textFocused = false
        owner.present { id in
            FruitPopupRequest(id: id, character: .blueberry,
                message: removal ? "remove this user-provided context from this device? your other My Context selections will be kept."
                    : "save, discard or keep editing your unsaved context changes?",
                primaryAction: .init(label: removal ? "keep this context" : "keep editing") {
                    guard ownerIsActive else { return }
                    _ = owner.consumeAction(for: id)
                },
                secondaryAction: .init(label: removal ? "remove context" : "save changes") {
                    guard ownerIsActive, owner.consumeAction(for: id) else { return }
                    pendingAction = removal ? .remove : .save
                },
                tertiaryAction: removal ? nil : .init(label: "discard changes") {
                    guard ownerIsActive, owner.consumeAction(for: id) else { return }
                    pendingAction = .discard
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "personal-health-confirmation", deduplicationKey: "personal-health-confirmation-" + popupInstanceID.uuidString,
                surface: .tapedWhite)
        }
    }

    private func save(status: FruitfolioPersonalHealthStatus) {
        do {
            try store.savePersonalHealth(category, text: text, status: status,
                provenance: clinicianConfirmed ? .userReportsClinicianConfirmed : .userProvided,
                expectedRevision: baselineRevision)
            onClose()
        } catch {
            errorMessage = error.localizedDescription
            errorFocusRequest = UUID()
        }
    }
}

#if DEBUG
struct FruitfolioPersonalHealthRegressionHarness: View {
    @StateObject private var store: Prompt27AContextStore
    private let suite: String
    init() {
        let suite = "fruitfolio.personalHealthQA." + UUID().uuidString
        self.suite = suite
        _store = StateObject(wrappedValue: Prompt27AContextStore(defaults: UserDefaults(suiteName: suite) ?? .standard, key: suite))
    }
    var body: some View {
        FruitfolioPersonalHealthContextView(store: store, onBack: {})
            .onDisappear {
                UserDefaults.standard.removeObject(forKey: suite)
                UserDefaults.standard.removePersistentDomain(forName: suite)
            }
    }
}
#endif
