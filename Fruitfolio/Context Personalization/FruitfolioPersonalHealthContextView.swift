import SwiftUI

struct FruitfolioPersonalHealthContextView: View {
    @ObservedObject var store: Prompt27AContextStore
    let onBack: () -> Void
    @State private var editing: FruitfolioPersonalHealthCategory?
    @EnvironmentObject private var motionPreferences: MotionPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BackControl(action: onBack)
                Text("personal health context").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Text("entirely optional, user-provided context, stored on this device. explore only what matters to you. skip anything; no biological findings or diagnoses are guessed from your answers. these notes do not replace approved research or clinical advice.")
                Text("for laboratory artwork, choose a technique or sample category only if it was actually reported or you know it applies. otherwise use other labs / testing.")
                    .font(.callout)
                if store.didRecoverCorruptStoredContext {
                    Text("your existing context could not be read. it has been preserved and changes are paused. use My Context’s confirmed clear action only if you want to erase it.")
                }
                ForEach(FruitfolioPersonalHealthGroup.allCases) { group in
                    DisclosureGroup {
                        VStack(spacing: 12) {
                            ForEach(FruitfolioPersonalHealthCategory.allCases.filter { $0.group == group }) { category in
                                Button { editing = category } label: {
                                    HStack(alignment: .center, spacing: 14) {
                                        if let asset = category.asset {
                                            FruitfolioImage(id: asset).scaledToFit().frame(width: 64, height: 64).accessibilityHidden(true)
                                        }
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(LocalizedStringKey(category.title)).multilineTextAlignment(.leading)
                                            Text(status(category)).font(.caption)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(minHeight: 64)
                                }
                                .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                                .disabled(store.didRecoverCorruptStoredContext)
                                .accessibilityLabel(category.title)
                                .accessibilityValue(status(category))
                                .accessibilityHint("opens an optional editable context field")
                            }
                        }
                        .padding(.vertical, 12)
                    } label: {
                        Text(LocalizedStringKey(group.title)).font(.headline).frame(minHeight: 44)
                    }
                }
            }
            .padding(20).frame(maxWidth: 680, alignment: .leading).frame(maxWidth: .infinity)
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .sheet(item: $editing) { category in
            FruitfolioPersonalHealthEntryEditor(store: store, category: category, onClose: { editing = nil })
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
    @State private var confirmDiscard = false
    @State private var confirmRemove = false
    @State private var errorMessage: String?
    private let baselineText: String
    private let baselineConfirmation: Bool

    init(store: Prompt27AContextStore, category: FruitfolioPersonalHealthCategory, onClose: @escaping () -> Void) {
        self.store = store; self.category = category; self.onClose = onClose
        let record = store.context.personalHealthEntries[category.rawValue]
        let initial = record?.status == .provided ? (record?.text ?? "") : ""
        let confirmed = record?.status == .provided && record?.provenance == .userReportsClinicianConfirmed
        baselineText = initial; baselineConfirmation = confirmed
        _text = State(initialValue: initial); _clinicianConfirmed = State(initialValue: confirmed)
    }
    private var changed: Bool { text != baselineText || clinicianConfirmed != baselineConfirmation }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey(category.title)).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                if let asset = category.asset {
                    FruitfolioImage(id: asset).scaledToFit().frame(maxWidth: 100, maxHeight: 100).accessibilityHidden(true)
                }
                Text("anything you want Fruitfolio to know? this is your report, not something Fruitfolio has verified.")
                TextEditor(text: $text).frame(minHeight: 180).accessibilityLabel("optional personal health context")
                Text("\(text.count) / 10000 characters").font(.caption)
                Toggle("a clinician confirmed this information, as i report it", isOn: $clinicianConfirmed)
                if category.group == .genetics {
                    Text("record only findings or history you choose to supply. Fruitfolio will not infer a genotype, inheritance pattern, disease risk or diagnosis.").font(.callout)
                }
                if category == .knownOvulation {
                    Text("this remains user-reported history. it does not confirm ovulation or replace Cycle Tracker’s separately labeled estimates.").font(.callout)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(Color.red) }
                WatercolorPrimaryButton(label: "save my context") { save(status: .provided) }
                WatercolorSecondaryButton(label: "prefer not to say") { save(status: .preferNotToSay) }
                if store.context.personalHealthEntries[category.rawValue]?.isActive == true {
                    WatercolorSecondaryButton(label: "remove this context") { confirmRemove = true }
                }
                WatercolorSecondaryButton(label: "skip / close") {
                    if changed { confirmDiscard = true } else { onClose() }
                }
            }
            .padding(20).frame(maxWidth: 680, alignment: .leading).frame(maxWidth: .infinity)
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .interactiveDismissDisabled(changed)
        .confirmationDialog("save or discard your context changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("save changes") { save(status: .provided) }
            Button("discard changes", role: .destructive) { onClose() }
            Button("keep editing", role: .cancel) {}
        }
        .confirmationDialog("remove this user-provided context?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("remove context", role: .destructive) { save(status: .removed) }
            Button("cancel", role: .cancel) {}
        }
    }
    private func save(status: FruitfolioPersonalHealthStatus) {
        do {
            try store.savePersonalHealth(category, text: text, status: status,
                provenance: clinicianConfirmed ? .userReportsClinicianConfirmed : .userProvided)
            onClose()
        } catch { errorMessage = error.localizedDescription }
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
