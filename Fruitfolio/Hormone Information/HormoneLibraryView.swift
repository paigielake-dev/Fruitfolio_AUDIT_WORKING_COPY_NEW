import SwiftUI
import UIKit

struct FruitfolioHormoneLibraryView: View {
    let onBack: () -> Void
    private let articleLoader: @Sendable (FruitfolioMeasuredHormone) async throws -> FruitfolioHormoneLibraryArticle
    init(onBack: @escaping () -> Void,
         articleLoader: @escaping @Sendable (FruitfolioMeasuredHormone) async throws -> FruitfolioHormoneLibraryArticle = { hormone in
             try await FruitfolioHormoneLibraryProvider.shared.article(for: hormone)
         }) {
        self.onBack = onBack
        self.articleLoader = articleLoader
    }
    @State private var hormone: FruitfolioMeasuredHormone = .estradiol
    @State private var article: FruitfolioHormoneLibraryArticle?
    @State private var failedRequest: LoadKey?
    @State private var retryID = UUID()
    @State private var viewIsVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    private struct LoadKey: Hashable, Sendable {
        let hormone: FruitfolioMeasuredHormone
        let retryID: UUID
    }
    private var loadKey: LoadKey { .init(hormone: hormone, retryID: retryID) }
    private var canInteract: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active && popupCoordinator.currentPopup == nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BackControl(action: { guard canInteract else { return }; onBack() }).accessibilityIdentifier("hormoneLibrary.back")
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
                // Match before the async task starts; an old accepted article
                // must never appear beneath the newly selected hormone label.
                if let article, article.hormone == hormone {
                    VStack(alignment: .leading, spacing: 20) {
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
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("hormoneLibrary.article." + article.hormone.rawValue)
                } else if failedRequest == loadKey {
                    VStack(alignment: .leading, spacing: 12) {
                        FruitfolioFixedText(source: "the local hormone library could not be opened. your measurements have not changed.", serious: true)
                        WatercolorSecondaryButton(label: "try opening the library again") { [request = loadKey] in
                            guard canInteract, loadKey == request, failedRequest == request else { return }
                            retryID = UUID()
                        }
                        .accessibilityIdentifier("hormoneLibrary.retry")
                    }
                } else { ProgressView { FruitfolioFixedText(source: "looking through the approved library", serious: true) } }
            }
            .padding(20).frame(maxWidth: 680, alignment: .leading).frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("hormoneLibrary.scroll")
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .onAppear { viewIsVisible = true }
        .onDisappear { viewIsVisible = false }
        .task(id: loadKey) { [request = loadKey] in
            guard !Task.isCancelled, loadKey == request else { return }
            article = nil; failedRequest = nil
            do {
                let result = try await articleLoader(request.hormone)
                try Task.checkCancellation()
                guard loadKey == request else { return }
                guard result.hormone == request.hormone else {
                    failedRequest = request
                    return
                }
                article = result
            } catch {
                guard !Task.isCancelled, loadKey == request else { return }
                failedRequest = request
            }
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
