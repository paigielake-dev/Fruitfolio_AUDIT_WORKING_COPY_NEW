import SwiftUI

struct Prompt10SavedCitationsView: View {
    let page: Prompt10SavedPage
    @State private var legacyPackage: FruitfolioResearchPackage?
    @State private var loading = false
    @State private var couldNotLoad = false
    var body: some View {
        if !page.sourceIDs.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text(LocalizedStringKey(page.saveType == .excerpt ? "original answer sources" : "sources")).font(.custom("Chalkboard SE", size: 16, relativeTo: .headline)).bold()
                    .accessibilityAddTraits(.isHeader)
                if loading { ProgressView("opening saved references") }
                ForEach(Array(Prompt10SavedCitationResolver.resolve(page, package: legacyPackage).enumerated()), id: \.offset) { index, citation in
                    VStack(alignment: .leading, spacing: 6) {
                        if let reference = citation.reference {
                            Text(reference).textSelection(.enabled)
                                .accessibilityIdentifier("savedPage.reference." + String(index))
                            if citation.isSnapshot { Text("reference preserved as saved").font(.footnote) }
                            if let raw = citation.urlString, let url = URL(string: raw) {
                                Link("open source", destination: url).frame(minHeight: 44)
                            }
                        } else if !loading {
                            Text("the original source reference cannot be verified from the saved metadata. this page has not been assigned a different source.")
                                .accessibilityIdentifier("savedPage.unavailableReference." + String(index))
                        }
                    }
                }
                if couldNotLoad {
                    Button("try opening source references again") { Task { await loadLegacy() } }.frame(minHeight: 44)
                }
            }
            .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
            .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
            .task(id: page.id) { if page.sourceSnapshots == nil { await loadLegacy() } }
        }
    }
    private func loadLegacy() async {
        guard page.sourceSnapshots == nil else { return }
        loading = true; couldNotLoad = false
        do { legacyPackage = try await FruitfolioResearchPackageStore().load() }
        catch { couldNotLoad = true }
        loading = false
    }
}
