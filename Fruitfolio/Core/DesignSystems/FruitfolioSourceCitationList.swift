import SwiftUI

/// Renders original approved record fields verbatim, shared by Ask and saved
/// pages. Localization must never rewrite source titles or identifiers.
struct FruitfolioSourceCitationList: View {
    let sources: [AskSourceRecord]
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @State private var failedToOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            HStack(spacing: 8) {
                FruitfolioImage(id: .ask_source_pages)
                    .scaledToFit().frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                Text("sources ˚ ☆ ‧ ₊")
                    .font(.custom("Chalkboard SE", size: 15, relativeTo: .headline).bold())
                    .accessibilityAddTraits(.isHeader)
            }
            ForEach(sources) { source in
                HStack(alignment: .top, spacing: 8) {
                    FruitfolioImage(id: .ask_source_marker)
                        .scaledToFit().frame(width: 20, height: 20)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(verbatim: source.title)
                            .font(.custom("Chalkboard SE", size: 13, relativeTo: .callout).bold())
                        if let publication = source.publicationData, !publication.isEmpty {
                            Text(verbatim: publication).font(.caption)
                        }
                        Text(verbatim: source.id).font(.caption2).textSelection(.enabled)
                        if let doi = source.doi, !doi.isEmpty {
                            Text(verbatim: "DOI: " + doi).font(.caption).textSelection(.enabled)
                        }
                        if let address = source.urlString, !address.isEmpty {
                            Text(verbatim: address).font(.caption).textSelection(.enabled)
                        }
                        if let destination = Prompt09CitationDestination.url(sourceURL: source.urlString, doi: source.doi) {
                            Button("open source") {
                                audioManager.play(.buttonSoftPop)
                                openURL(destination) { accepted in failedToOpen = !accepted }
                            }
                            .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                            .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                            .accessibilityLabel(Text("open source: \(source.title)"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .fixedSize(horizontal: false, vertical: true)
        .alert("this source link could not be opened", isPresented: $failedToOpen) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("the citation details remain available here.")
        }
    }
}
