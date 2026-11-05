import SwiftUI

/// Translation is display-only. The source and all saved/user-authored records
/// remain unchanged. Language/source changes cancel obsolete inference tasks.
struct FruitfolioTranslatedContent<Content: View>: View {
    let source: String
    var protectedLiterals: [String] = []
    var enabled = true
    var sourceLanguage = "en"
    @ViewBuilder let content: (String, String) -> Content
    @EnvironmentObject private var settings: SettingsStore
    @State private var rendered: String?
    @State private var resolvedKey: Key?
    @State private var failure: String?

    private struct Key: Hashable {
        let source: String
        let language: FruitfolioLanguage
        let protectedLiterals: [String]
        let enabled: Bool
        let sourceLanguage: String
    }
    private var key: Key { Key(source: source, language: settings.language, protectedLiterals: protectedLiterals, enabled: enabled, sourceLanguage: sourceLanguage) }
    private var usesTranslation: Bool { enabled && settings.language.rawValue != sourceLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content(resolvedKey == key ? (rendered ?? source) : source,
                    resolvedKey == key && rendered != nil ? settings.language.rawValue : sourceLanguage)
            if usesTranslation {
                if resolvedKey == key, rendered != nil {
                    Text("local machine translation").font(.caption)
                    DisclosureGroup("original text") {
                        FruitfolioSemanticText(markdown: source).textSelection(.enabled)
                    }
                } else if resolvedKey == key, let failure {
                    Text("original text — translation unavailable").font(.caption).bold()
                    Text(LocalizedStringKey(failure)).font(.caption)
                } else {
                    Text("original text — preparing local translation…").font(.caption)
                }
            }
        }
        .task(id: key) {
            let request = key
            rendered = nil
            failure = nil
            resolvedKey = nil
            guard usesTranslation else { return }
            do {
                let result = try await FruitfolioTranslationService.shared.translate(
                    source, language: request.language, protectedLiterals: protectedLiterals,
                    sourceLanguage: request.sourceLanguage)
                try Task.checkCancellation()
                rendered = result
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
    var body: some View {
        let translationSource = semanticSpans.map(FruitfolioSemanticMarkup.markdown) ?? source
        FruitfolioTranslatedContent(source: translationSource, protectedLiterals: protectedLiterals, enabled: enabled, sourceLanguage: sourceLanguage) { display, _ in
            if let semanticSpans, display == translationSource {
                FruitfolioSemanticText(spans: FruitfolioSemanticPolicy.normalized(semanticSpans, serious: serious), baseFont: font, color: color)
            } else {
                FruitfolioSemanticText(markdown: display, baseFont: font, color: color, serious: serious)
            }
        }
    }
}
