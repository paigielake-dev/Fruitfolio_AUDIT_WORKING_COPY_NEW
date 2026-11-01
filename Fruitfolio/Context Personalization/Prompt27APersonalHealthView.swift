import SwiftUI

struct Prompt27APersonalHealthView: View {
    @ObservedObject var store: Prompt27AContextStore
    let onBack: () -> Void
    @State private var selected: Prompt27AHealthField?
    @EnvironmentObject private var motionPreferences: MotionPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BackControl(action: onBack)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("personal health context").font(.title2).bold().accessibilityAddTraits(.isHeader)
                    Text("all of this is optional. choose only what you want to share, or leave everything blank. these are your reported details, not a diagnosis or a prediction.")
                    Text("choose a testing category only if you know it applies. having a test does not mean a particular laboratory technique was used.")
                    ForEach(Prompt27AHealthField.allCases) { field in
                        Button { selected = field } label: {
                            HStack(spacing: 14) {
                                if let artwork = field.artwork {
                                    Image(artwork).resizable().scaledToFit().frame(width: 60, height: 60)
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(LocalizedStringKey(field.title)).fontWeight(.semibold)
                                    Text(LocalizedStringKey(status(field))).font(.footnote)
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                            .accessibilityHidden(true)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(LocalizedStringKey(field.title))
                        .accessibilityValue(LocalizedStringKey(status(field)))
                        .accessibilityHint("opens an optional editable field")
                        .accessibilityIdentifier("healthContext.field." + field.rawValue)
                        .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                    }
                    Text("medication history stays separate from the structured birth-control and fertility-medication questions. these notes do not automatically change predictions.")
                }
                .frame(maxWidth: 620, alignment: .leading).frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("healthContext.scroll")
        }
        .padding(20)
        .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .sheet(item: $selected) { field in Prompt27AHealthEntryEditor(store: store, field: field) }
    }

    private func status(_ field: Prompt27AHealthField) -> String {
        guard let value = store.context.personalHealthFields[field] else { return "optional • not provided" }
        switch value.status {
        case .supplied: return "your reported context • saved"
        case .preferNotToSay: return "prefer not to say"
        case .removed: return "optional • removed"
        }
    }
}

private struct Prompt27AHealthEntryEditor: View {
    @ObservedObject var store: Prompt27AContextStore
    let field: Prompt27AHealthField
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var clinicianConfirmed: Bool
    @State private var confirmDiscard = false
    @State private var confirmRemove = false
    @FocusState private var focused: Bool
    private let initialText: String
    private let initialConfirmed: Bool

    init(store: Prompt27AContextStore, field: Prompt27AHealthField) {
        self.store = store; self.field = field
        let existing = store.context.personalHealthFields[field]
        let text = existing?.text ?? ""
        let confirmed = existing?.provenance == .clinicianConfirmedAsReportedByUser
        self.initialText = text; self.initialConfirmed = confirmed
        _text = State(initialValue: text); _clinicianConfirmed = State(initialValue: confirmed)
    }
    private var changed: Bool { text != initialText || clinicianConfirmed != initialConfirmed }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(LocalizedStringKey(field.title)).font(.title2).bold()
                if let artwork = field.artwork { Image(artwork).resizable().scaledToFit().frame(maxWidth: 120).accessibilityHidden(true) }
                Text("anything you want Fruitfolio to know?")
                TextField("optional history", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder).lineLimit(5...12).focused($focused)
                    .accessibilityIdentifier("healthContext.entryText")
                Toggle("a clinician confirmed this, according to what I was told", isOn: $clinicianConfirmed)
                    .accessibilityIdentifier("healthContext.clinicianReported")
                Text("saved as information you provide. Fruitfolio does not independently verify this or infer a diagnosis, genetic finding, or laboratory method.")
                FruitfolioControlPillButton(label: "save context") {
                    store.setPersonalHealthField(field, text: text, clinicianConfirmedByUser: clinicianConfirmed); dismiss()
                }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                FruitfolioControlPillButton(label: "prefer not to say") {
                    store.setPersonalHealthField(field, text: "", status: .preferNotToSay); dismiss()
                }
                FruitfolioControlPillButton(label: "remove this context") { confirmRemove = true }
                    .disabled(store.context.personalHealthFields[field]?.status != .supplied)
                FruitfolioControlPillButton(label: "skip / cancel") {
                    if changed { confirmDiscard = true } else { dismiss() }
                }
            }.padding(20).frame(maxWidth: 620, alignment: .leading).frame(maxWidth: .infinity)
        }
        .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            if focused {
                HStack { Spacer(); Button("done") { focused = false }.frame(minWidth: 44, minHeight: 44) }
                    .padding(.horizontal, 20).background(DesignTokens.ColorToken.backgroundCream)
            }
        }
        .interactiveDismissDisabled(changed)
        .confirmationDialog("discard unsaved context?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("discard", role: .destructive) { dismiss() }
            Button("keep editing", role: .cancel) { }
        }
        .alert("remove this context?", isPresented: $confirmRemove) {
            Button("remove", role: .destructive) { store.setPersonalHealthField(field, text: "", status: .removed); dismiss() }
            Button("cancel", role: .cancel) { }
        } message: { Text("the saved details will be removed. your cycle history and measurements stay unchanged.") }
    }
}
