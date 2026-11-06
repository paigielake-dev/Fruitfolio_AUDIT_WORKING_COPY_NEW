import SwiftUI

/// Translation is display-only. The source and all saved/user-authored records
/// remain unchanged. Language/source changes cancel obsolete inference tasks.
struct FruitfolioTranslatedContent<Content: View>: View {
    let source: String
    var protectedLiterals: [String] = []
    var sourceRecords: [AskSourceRecord] = []
    var enabled = true
    var sourceLanguage = "en"
    var bundle: Bundle = .main
    @ViewBuilder let content: (String, String) -> Content
    @EnvironmentObject private var settings: SettingsStore
    @State private var rendered: String?
    @State private var resolvedKey: Key?
    @State private var failure: String?
    @State private var translationOrigin: FruitfolioTranslationOrigin?
    @State private var showOriginal = false

    private struct Key: Hashable {
        let source: String
        let language: FruitfolioLanguage
        let protectedLiterals: [String]
        let enabled: Bool
        let sourceLanguage: String
        let bundlePath: String
    }
    private struct TaskKey: Hashable {
        let sourceKey: Key
        let paused: Bool
    }
    private var key: Key { Key(source: source, language: settings.language, protectedLiterals: FruitfolioCitationProtection.literals(ids: protectedLiterals, records: sourceRecords), enabled: enabled, sourceLanguage: sourceLanguage, bundlePath: bundle.bundleURL.path) }
    private var usesTranslation: Bool { enabled && settings.language.rawValue != sourceLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content(resolvedKey == key ? (rendered ?? source) : source,
                    resolvedKey == key && rendered != nil ? settings.language.rawValue : sourceLanguage)
            if usesTranslation {
                if resolvedKey == key, rendered != nil {
                    if translationOrigin == .machine { Text("local machine translation").font(.caption) }
                    FruitfolioControlPillButton(label: showOriginal ? "hide original text" : "show original text", isSelected: showOriginal) {
                        showOriginal.toggle()
                    }
                    .controlSize(.small)
                    .accessibilityIdentifier("translation.originalToggle")
                    if showOriginal {
                        FruitfolioSemanticText(markdown: source).textSelection(.enabled)
                            .accessibilityIdentifier("translation.originalText")
                    }
                } else if resolvedKey == key, let failure {
                    Text("original text — translation unavailable").font(.caption).bold()
                    Text(LocalizedStringKey(failure)).font(.caption)
                    if settings.translationPausedForMemoryPressure {
                        FruitfolioControlPillButton(label: "try translation again") {
                            settings.translationPausedForMemoryPressure = false
                        }
                        .controlSize(.small)
                        .accessibilityIdentifier("translation.retryAfterMemoryPressure")
                    }
                } else {
                    Text("original text — preparing local translation…").font(.caption)
                }
            }
        }
        .task(id: TaskKey(sourceKey: key, paused: settings.translationPausedForMemoryPressure)) {
            let request = key
            // Accepted display text remains valid when native allocations are
            // released. A new unresolved key can still use its small catalog
            // entry while inference is paused; that lookup runs on the actor.
            if resolvedKey == request, rendered != nil { return }
            rendered = nil
            failure = nil
            resolvedKey = nil
            translationOrigin = nil
            guard usesTranslation else { return }
            do {
                let result = try await FruitfolioTranslationService.shared.translateForDisplay(
                    request.source, language: request.language, protectedLiterals: request.protectedLiterals,
                    sourceLanguage: request.sourceLanguage,
                    inferenceAllowed: !settings.translationPausedForMemoryPressure, bundle: bundle)
                try Task.checkCancellation()
                rendered = result.text
                translationOrigin = result.origin
                resolvedKey = request
            } catch {
                guard !Task.isCancelled else { return }
                failure = error.localizedDescription
                resolvedKey = request
            }
        }
    }
}

struct FruitfolioTranslatedText: View {
    let source: String
    var protectedLiterals: [String] = []
    var enabled = true
    var font: Font = .body
    var color: Color? = nil
    var serious = false
    var sourceLanguage = "en"
    var semanticSpans: [FruitfolioSemanticSpan]?
    var sourceRecords: [AskSourceRecord] = []
    var body: some View {
        let translationSource = semanticSpans.map(FruitfolioSemanticMarkup.markdown) ?? source
        FruitfolioTranslatedContent(source: translationSource, protectedLiterals: protectedLiterals, sourceRecords: sourceRecords, enabled: enabled, sourceLanguage: sourceLanguage) { display, _ in
            if let semanticSpans, display == translationSource {
                FruitfolioSemanticText(spans: FruitfolioSemanticPolicy.normalized(semanticSpans, serious: serious), baseFont: font, color: color)
            } else {
                FruitfolioSemanticText(markdown: display, baseFont: font, color: color, serious: serious)
            }
        }
    }
}

/// Short, fixed interface copy. One existing translation-state owner provides
/// source/catalog/machine provenance without adding long-form action controls.
/// Saved scientific or user-authored bodies keep FruitfolioTranslatedText.
struct FruitfolioFixedText: View {
    let source: String
    var protectedLiterals: [String] = []
    var font: Font = .body
    var color: Color? = nil
    var serious = false
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var translation = FruitfolioControlTranslationState()

    var body: some View {
        let key = FruitfolioControlTranslationState.Key(source: source, language: settings.language, protectedLiterals: protectedLiterals)
        let presentation = translation.presentation(for: key)
        VStack(alignment: .leading, spacing: 4) {
            FruitfolioSemanticText(markdown: presentation.text, baseFont: font, color: color, serious: serious)
            if let caption = presentation.status.captionKey {
                Text(verbatim: settings.localized(caption))
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text(presentation.status.accessibilityDetail(original: source, localized: { settings.localized($0) })))
        .task(id: FruitfolioControlTranslationState.TaskKey(key: key,
            inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
            await translation.resolve(key, inferenceAllowed: !settings.translationPausedForMemoryPressure)
        }
    }
}

/// A native field whose fixed prompt follows the app language. The binding is
/// forwarded unchanged; translation never reads or rewrites the entered value.
struct FruitfolioFixedTextField: View {
    let source: String
    @Binding private var text: String
    let axis: Axis
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var translation = FruitfolioControlTranslationState()

    init(_ source: String, text: Binding<String>, axis: Axis = .horizontal) {
        self.source = source
        self._text = text
        self.axis = axis
    }

    var body: some View {
        let key = FruitfolioControlTranslationState.Key(source: source, language: settings.language)
        let presentation = translation.presentation(for: key)
        TextField(presentation.text, text: $text, axis: axis)
            .accessibilityLabel(Text(verbatim: presentation.text))
            .accessibilityHint(Text(presentation.status.accessibilityDetail(original: source, localized: { settings.localized($0) })))
            .task(id: FruitfolioControlTranslationState.TaskKey(key: key,
                inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
                await translation.resolve(key, inferenceAllowed: !settings.translationPausedForMemoryPressure)
            }
    }
}


/// Translates only the fixed accessible label. The native editor receives the
/// original patient binding; entered text is never supplied to translation.
struct FruitfolioFixedTextEditor: View {
    let source: String
    @Binding private var text: String
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var translation = FruitfolioControlTranslationState()

    init(_ source: String, text: Binding<String>) {
        self.source = source
        self._text = text
    }

    var body: some View {
        let key = FruitfolioControlTranslationState.Key(source: source, language: settings.language)
        let presentation = translation.presentation(for: key)
        TextEditor(text: $text)
            .accessibilityLabel(Text(verbatim: presentation.text))
            .accessibilityHint(Text(presentation.status.accessibilityDetail(original: source, localized: { settings.localized($0) })))
            .task(id: FruitfolioControlTranslationState.TaskKey(key: key,
                inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
                await translation.resolve(key, inferenceAllowed: !settings.translationPausedForMemoryPressure)
            }
    }
}

#if DEBUG
/// Private, nonclinical catalog fixture. No production catalog/resource is
/// edited and no fixture string is evidence of real localization approval.
@MainActor
private final class FruitfolioTranslationDisclosureFixture: ObservableObject {
    private let catalog: FruitfolioTranslationCatalogRegressionFixture?
    var bundle: Bundle? { catalog?.bundle }
    let issue: String?
    init() {
        do { catalog = try FruitfolioTranslationCatalogRegressionFixture(); issue = nil }
        catch { catalog = nil; issue = "synthetic catalog fixture could not be created" }
    }
}

struct FruitfolioTranslationDisclosureRegressionHarness: View {
    @StateObject private var fixture = FruitfolioTranslationDisclosureFixture()
    @State private var configured = false
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audio: AudioManager
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("synthetic catalog UI fixture — not research or language approval").font(.caption)
                if let bundle = fixture.bundle {
                    FruitfolioTranslatedContent(source: "**fixture source**", bundle: bundle) { display, _ in
                        FruitfolioSemanticText(markdown: display)
                            .accessibilityIdentifier("translationQA.displayed")
                    }
                } else { Text(fixture.issue ?? "fixture unavailable") }
                FruitfolioInteractionSoundDiagnostics()
            }
            .padding(20)
        }
        .task {
            guard !configured else { return }
            configured = true
            let args = ProcessInfo.processInfo.arguments
            settings.language = .french
            settings.translationPausedForMemoryPressure = true
            settings.reduceAnimationOverride = args.contains("-fruitfolioTranslationDisclosureReduceMotion")
            settings.globallyMuted = args.contains("-fruitfolioAudioMuted")
            settings.soundEffectsEnabled = true
            settings.soundEffectsVolume = 0.5
            audio.debugRecordInteractions(true)
        }
    }
}
#endif

/// Fixed accessible copy for existing artwork and controls; uses the same
/// translation owner and explicit provenance as other compact interface copy.
@MainActor
struct FruitfolioFixedAccessibilityLabel: ViewModifier {
    let source: String
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var translation = FruitfolioControlTranslationState()
    private var key: FruitfolioControlTranslationState.Key {
        .init(source: source, language: settings.language)
    }
    func body(content: Content) -> some View {
        let display = translation.presentation(for: key)
        content
            .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: display.text)))
            .accessibilityHint(Text(display.status.accessibilityDetail(original: source,
                localized: { settings.localized($0) })))
            .task(id: FruitfolioControlTranslationState.TaskKey(key: key,
                inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
                await translation.resolve(key, inferenceAllowed: !settings.translationPausedForMemoryPressure)
            }
    }
}
