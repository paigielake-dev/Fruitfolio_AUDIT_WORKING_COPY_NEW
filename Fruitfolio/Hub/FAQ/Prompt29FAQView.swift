import SwiftUI

struct Prompt29FAQView: View {
    let onBack: () -> Void

    @State private var expanded: Set<String> = []

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Prompt29FAQCatalog.sections) { section in
                        Prompt29FAQSectionCard(
                            section: section,
                            expanded: $expanded
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 42)
                .frame(maxWidth: DesignTokens.Layout.compactReadingMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .top, spacing: 0) {
                FruitfolioDecoratedRouteHeader(palette: .faq) {
                    Prompt12RouteHeader(title: "FAQ", subtitle: "you’ve got questions. we’ve got answers. ♡",
                                        assetName: nil, onBack: onBack)
                }
                .padding(.horizontal, 20)
                .background(DesignTokens.ColorToken.backgroundCream)
            }

        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct Prompt29FAQSectionCard: View {
    let section: Prompt29FAQSection
    @Binding var expanded: Set<String>
    @State private var showLifeBridge = false
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FruitfolioTranslatedText(source: section.title,
                font: .custom("Chalkboard SE", size: 16, relativeTo: .headline), serious: true)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            ForEach(section.items) { item in
                let isExpanded = expanded.contains(item.id)
                Prompt29FAQQuestionButton(item: item, isExpanded: isExpanded) {
                    if expanded.remove(item.id) == nil { expanded.insert(item.id) }
                }
                if isExpanded {
                    FruitfolioTranslatedText(source: item.answer,
                                             font: .custom("Chalkboard SE", size: 12.5, relativeTo: .body), serious: true)
                        .font(.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .accessibilityIdentifier("faq.answer.\(item.id)")
                    if item.id == "lifebridge-information" {
                        WatercolorSecondaryButton(label: "open LifeBridge information") { showLifeBridge = true }
                    }
                }
            }
        }
        .sheet(isPresented: $showLifeBridge) {
            FruitfolioPresentedPopupHost {
                FruitfolioLifeBridgeInformationView(onBack: { showLifeBridge = false })
            }
        }
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .padding(16)
        .background(
            DesignTokens.ColorToken.backgroundCream.opacity(0.88),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .stroke(
                DesignTokens.ColorToken.primaryBurgundy.opacity(0.13),
                lineWidth: 1
            )
        }
    }

    private func expansionBinding(
        for itemID: String
    ) -> Binding<Bool> {
        Binding(
            get: {
                expanded.contains(itemID)
            },
            set: {
                if $0 {
                    expanded.insert(itemID)
                } else {
                    expanded.remove(itemID)
                }
            }
        )
    }
}

/// A single disclosure button: translation presentation never nests a second
/// button or original-text DisclosureGroup inside its label.
@MainActor
private struct Prompt29FAQQuestionButton: View {
    let item: Prompt29FAQItem
    let isExpanded: Bool
    let action: () -> Void
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager
    @StateObject private var questionTranslation = FruitfolioControlTranslationState()
    @StateObject private var stateTranslation = FruitfolioControlTranslationState()
    private var questionKey: FruitfolioControlTranslationState.Key {
        .init(source: item.question, language: settings.language)
    }
    private var stateKey: FruitfolioControlTranslationState.Key {
        .init(source: isExpanded ? "expanded" : "collapsed", language: settings.language)
    }

    var body: some View {
        let question = questionTranslation.presentation(for: questionKey)
        let state = stateTranslation.presentation(for: stateKey)
        Button {
            audioManager.play(.buttonSoftPop)
            action()
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: FruitfolioSemanticDocument.plainText(from: question.text))
                        .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                        .fontWeight(.regular)
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                    if let status = question.status.captionKey {
                        Text(LocalizedStringKey(status)).font(.caption)
                    }
                }
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image("control_next")
                    .resizable().scaledToFit().frame(width: 22, height: 22)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .flipsForRightToLeftLayoutDirection(true)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
        .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: question.text)))
        .accessibilityValue(Text(FruitfolioSemanticDocument.plainText(from: state.text)))
        .accessibilityHint(Text([
            question.status.accessibilityDetail(original: questionKey.source, localized: { settings.localized($0) }),
            state.status.accessibilityDetail(original: stateKey.source, localized: { settings.localized($0) })
        ].filter { !$0.isEmpty }.joined(separator: ". ")))
        .accessibilityIdentifier("faq.question.\(item.id)")
        .task(id: FruitfolioControlTranslationState.TaskKey(key: questionKey,
            inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
            await questionTranslation.resolve(questionKey, inferenceAllowed: !settings.translationPausedForMemoryPressure)
        }
        .task(id: FruitfolioControlTranslationState.TaskKey(key: stateKey,
            inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
            await stateTranslation.resolve(stateKey, inferenceAllowed: !settings.translationPausedForMemoryPressure)
        }
    }
}
