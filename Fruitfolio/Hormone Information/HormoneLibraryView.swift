import SwiftUI

struct FruitfolioHormoneLibraryView: View {
    let onBack: () -> Void
    @State private var hormone: FruitfolioMeasuredHormone = .estradiol
    @State private var article: FruitfolioHormoneLibraryArticle?
    @State private var unavailable = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BackControl(action: onBack).accessibilityIdentifier("hormoneLibrary.back")
                FruitfolioFixedText(source: "hormone library", font: .title2.bold(), serious: true).accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("hormoneLibrary.heading")
                Picker(selection: $hormone) {
                    ForEach(FruitfolioMeasuredHormone.allCases.filter { $0 != .other }) { item in
                        FruitfolioFixedText(source: item.label, protectedLiterals: item.protectedAbbreviations, serious: true).tag(item)
                    }
                } label: { FruitfolioFixedText(source: "educational hormone", serious: true) }
                .accessibilityIdentifier("hormoneLibrary.hormone")
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                if let asset = artwork {
                    FruitfolioImage(id: asset).scaledToFit().frame(maxWidth: 100, maxHeight: 100)
                        .accessibilityHidden(true)
                }
                FruitfolioTranslatedText(source: "educational library excerpts, not an interpretation of your measurements. keep each excerpt’s original topic and source context in view. coverage is partial; these sections do not establish a diagnosis, normal range or treatment recommendation.", font: .callout, serious: true)
                    .accessibilityIdentifier("hormoneLibrary.context")
                if let article {
                    ForEach(FruitfolioHormoneLibrarySection.allCases) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            FruitfolioFixedText(source: section.title, font: .headline, serious: true).accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("hormoneLibrary.section." + section.rawValue)
                            if let excerpt = article.excerpts.first(where: { $0.section == section }) {
                                Text(verbatim: excerpt.heading).font(.caption.bold())
                                FruitfolioTranslatedText(source: excerpt.presentation, protectedLiterals: excerpt.sources.map(\.id),
                                    font: .custom("Chalkboard SE", size: 15, relativeTo: .body), serious: true, sourceRecords: excerpt.sources)
                                FruitfolioSourceCitationList(sources: excerpt.sources)
                            } else {
                                FruitfolioFixedText(source: "details not available in the approved library yet.", font: .callout, serious: true)
                            }
                        }
                    }
                } else if unavailable {
                    FruitfolioFixedText(source: "the local hormone library could not be opened. your measurements have not changed.", serious: true)
                } else { ProgressView { FruitfolioFixedText(source: "looking through the approved library", serious: true) } }
            }
            .padding(20).frame(maxWidth: 680, alignment: .leading).frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("hormoneLibrary.scroll")
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .task(id: hormone) {
            article = nil; unavailable = false
            do {
                let result = try await FruitfolioHormoneLibraryProvider.shared.article(for: hormone)
                try Task.checkCancellation()
                article = result
            } catch { if !Task.isCancelled { unavailable = true } }
        }
    }
    private var artwork: FruitfolioAssetID? {
        switch hormone {
        case .estradiol: return .hormone_estrogen
        case .progesterone: return .hormone_progesterone
        case .testosterone: return .hormone_testosterone
        default: return nil
        }
    }
}
