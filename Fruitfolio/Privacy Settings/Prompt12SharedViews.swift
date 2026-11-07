import SwiftUI

struct Prompt12PaperCard<Content: View>: View {
    let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            DesignTokens.ColorToken.backgroundCream.opacity(0.84),
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
                DesignTokens.ColorToken.secondaryBurgundy.opacity(0.13),
                lineWidth: 1
            )
        }
    }
}

struct Prompt12RouteHeader: View {
    let title: String
    let subtitle: String
    let assetName: String?
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                HStack {
                    BackControl {
                        onBack()
                    }
                    .accessibilityIdentifier("settings.routeHeader.back")

                    Spacer()
                }

                FruitfolioTranslatedContent(source: title, protectedLiterals: ["Fruitfolio", "LifeBridge"]) { display, _ in
                    FruitfolioSemanticText(markdown: display,
                        baseFont: .custom("Chalkboard SE", size: 25, relativeTo: .title),
                        color: DesignTokens.ColorToken.primaryBurgundy)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("settings.routeHeader.title")
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 58)
            }

            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }

            FruitfolioTranslatedText(source: subtitle, protectedLiterals: ["Fruitfolio", "LifeBridge"],
                font: .custom("Chalkboard SE", size: 12.5, relativeTo: .subheadline),
                color: DesignTokens.ColorToken.secondaryBurgundy)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300)
        }
        .padding(.top, 10)
    }
}

@MainActor
struct Prompt12NavigationRow: View {
    let title: String
    let detail: String?
    let assetName: String?
    let action: () -> Void

    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var titleTranslation = FruitfolioControlTranslationState()
    @StateObject private var detailTranslation = FruitfolioControlTranslationState()
    private var titleKey: FruitfolioControlTranslationState.Key { .init(source: title, language: settings.language) }
    private var detailKey: FruitfolioControlTranslationState.Key { .init(source: detail ?? "", language: settings.language) }

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    @EnvironmentObject
    private var audioManager: AudioManager

    var body: some View {
        let heading = titleTranslation.presentation(for: titleKey)
        let explanation = detailTranslation.presentation(for: detailKey)
        Button {
            audioManager.play(.buttonSoftPop)
            action()
        } label: {
            HStack(spacing: 10) {
                if let assetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)
                }

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    FruitfolioSemanticText(markdown: heading.text,
                        baseFont: .custom("Chalkboard SE", size: 13, relativeTo: .headline),
                        color: DesignTokens.ColorToken.primaryBurgundy)
                        .fontWeight(.bold)
                    statusCaption(heading.status)
                    if detail != nil {
                        FruitfolioSemanticText(markdown: explanation.text,
                            baseFont: .custom("Chalkboard SE", size: 10.5, relativeTo: .body),
                            color: DesignTokens.ColorToken.secondaryBurgundy)
                        statusCaption(explanation.status)
                    }
                }

                Spacer()

                Image("control_next")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 18,
                        height: 18
                    )
                    .accessibilityHidden(true)
            }
            .frame(
                minHeight:
                    DesignTokens
                        .Layout
                        .minimumHitTarget
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences
                        .reduceMotionActive
            )
        )
        .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: heading.text)))
        .accessibilityHint(Text(accessibilityDetail(heading, explanation)))
        .task(id: FruitfolioControlTranslationState.TaskKey(key: titleKey,
            inferenceAllowed: settings.translationInferenceAllowed)) {
            await titleTranslation.resolve(titleKey, inferenceAllowed: settings.translationInferenceAllowed)
        }
        .task(id: FruitfolioControlTranslationState.TaskKey(key: detailKey,
            inferenceAllowed: settings.translationInferenceAllowed)) {
            if detail != nil {
                await detailTranslation.resolve(detailKey, inferenceAllowed: settings.translationInferenceAllowed)
            }
        }
    }

    @ViewBuilder
    private func statusCaption(_ status: FruitfolioControlTranslationState.Presentation.Status) -> some View {
        if let key = status.captionKey {
            Text(LocalizedStringKey(key))
                .font(.custom("Chalkboard SE", size: 11, relativeTo: .caption))
                .foregroundStyle(DesignTokens.ColorToken.secondaryBurgundy)
        }
    }
    private func accessibilityDetail(_ heading: FruitfolioControlTranslationState.Presentation,
                                     _ explanation: FruitfolioControlTranslationState.Presentation) -> String {
        var parts = [heading.status.accessibilityDetail(
            original: FruitfolioSemanticDocument.plainText(from: title), localized: { settings.localized($0) })]
        if let detail {
            parts.insert(FruitfolioSemanticDocument.plainText(from: explanation.text), at: 0)
            parts.append(explanation.status.accessibilityDetail(
                original: FruitfolioSemanticDocument.plainText(from: detail), localized: { settings.localized($0) }))
        }
        return parts.filter { !$0.isEmpty }.joined(separator: ". ")
    }
}

private struct Prompt12NavigationRowPopStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                reduceMotion
                    ? 1
                    : (
                        configuration.isPressed
                        ? 0.88
                        : 1
                    )
            )
            .offset(
                y:
                    reduceMotion
                    ? 0
                    : (
                        configuration.isPressed
                        ? 5
                        : 0
                    )
            )
            .rotationEffect(
                .degrees(
                    reduceMotion
                        ? 0
                        : (
                            configuration.isPressed
                            ? -1.2
                            : 0
                        )
                )
            )
            .brightness(
                reduceMotion
                    ? 0
                    : (
                        configuration.isPressed
                        ? -0.04
                        : 0
                    )
            )
            .animation(
                reduceMotion
                    ? .easeOut(
                        duration: 0.08
                    )
                    : .spring(
                        response: 0.20,
                        dampingFraction: 0.38,
                        blendDuration: 0
                    ),
                value:
                    configuration
                        .isPressed
            )
    }
}

struct Prompt12StatusPill: View {
    let text: String
    let assetName: String?
    var protectedLiterals: [String] = []

    var body: some View {
        HStack(spacing: 6) {
            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 18,
                        height: 18
                    )
                    .accessibilityHidden(true)
            }

            FruitfolioTranslatedText(source: text, protectedLiterals: protectedLiterals + ["Fruitfolio", "LifeBridge"],
                font: .custom("Chalkboard SE", size: 10.5, relativeTo: .caption),
                color: DesignTokens.ColorToken.primaryBurgundy)
                .fontWeight(.bold)
        }
        .padding(
            .horizontal,
            10
        )
        .padding(
            .vertical,
            7
        )
        .background(
            DesignTokens
                .ColorToken
                .backgroundCream
                .opacity(0.90),
            in: Capsule()
        )
    }
}

struct Prompt12InfoText: View {
    let text: String
    let protectedLiterals: [String]

    init(_ text: String, protectedLiterals: [String] = []) {
        self.text = text
        self.protectedLiterals = protectedLiterals + ["Fruitfolio", "LifeBridge"]
    }

    var body: some View {
        FruitfolioTranslatedText(source: text, protectedLiterals: protectedLiterals,
            font: .custom("Chalkboard SE", size: 11.5, relativeTo: .body),
            color: DesignTokens.ColorToken.secondaryBurgundy, serious: true)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}


@MainActor
struct Prompt12VolumeRow: View {
    let title: String
    @Binding var value: Double
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var translation = FruitfolioControlTranslationState()
    private var key: FruitfolioControlTranslationState.Key { .init(source: title, language: settings.language) }
    var body: some View {
        let display = translation.presentation(for: key)
        VStack(alignment: .leading, spacing: 8) {
            FruitfolioSemanticText(markdown: display.text,
                baseFont: .custom("Chalkboard SE", size: 14, relativeTo: .body),
                color: DesignTokens.ColorToken.primaryBurgundy)
            if let caption = display.status.captionKey {
                Text(LocalizedStringKey(caption))
                    .font(.custom("Chalkboard SE", size: 11, relativeTo: .caption))
            }
            Slider(value: $value, in: 0...1)
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                .contentShape(Rectangle())
                .tint(DesignTokens.ColorToken.primaryBurgundy)
                .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: display.text)))
                .accessibilityHint(Text(display.status.accessibilityDetail(
                    original: FruitfolioSemanticDocument.plainText(from: title), localized: { settings.localized($0) })))
                .accessibilityValue(Text(FruitfolioSettingsPercentage.string(value,
                    locale: Locale(identifier: settings.language.localeIdentifier)) ?? settings.localized("volume unavailable")))
        }
        .frame(minHeight: 44)
        .task(id: FruitfolioControlTranslationState.TaskKey(key: key,
            inferenceAllowed: settings.translationInferenceAllowed)) {
            await translation.resolve(key, inferenceAllowed: settings.translationInferenceAllowed)
        }
    }
}

/// Inline, scrollable with the existing page; never traps navigation behind an alert.
struct Prompt12SavedRecordNotice: View {
    @ObservedObject var store: Prompt12AccountPrivacyStore

    var body: some View {
        if let message = store.persistenceRecoveryMessage {
            Prompt12PaperCard {
                FruitfolioTranslatedContent(source: message) { value, _ in
                    Prompt12InfoText(value)
                }
                WatercolorSecondaryButton(label: "reload saved record") {
                    store.reloadSavedAccountState()
                }
                .accessibilityIdentifier("account.reloadSavedRecord")
            }
            .accessibilityIdentifier("account.savedRecordNotice")
        }
    }
}
