import SwiftUI

/// Renders original approved record fields verbatim, shared by Ask and saved
/// pages. Localization must never rewrite source titles or identifiers.
struct FruitfolioSourceCitationList: View {
    let sources: [AskSourceRecord]
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @AccessibilityFocusState private var focusedSourceID: String?
    @State private var activeLinkID: UUID?
    @State private var ownedPopupID: UUID?
    @State private var returnFocusSourceID: String?
    @State private var isVisible = false
    @State private var instanceID = UUID()

    var body: some View {
        if !sources.isEmpty {
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
                        if let citation = source.sourceText, !citation.isEmpty, citation != source.title {
                            Text(verbatim: citation).font(.caption).textSelection(.enabled)
                        }
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
                                openSource(destination, sourceID: source.id)
                            }
                            .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                            .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                            .accessibilityLabel(Text("open source: \(source.title)"))
                            .accessibilityIdentifier("sourceCitation.open.\(source.id)")
                            .accessibilityFocused($focusedSourceID, equals: source.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false; cancelOwnedRequest() }
        .onChange(of: sources) { _, _ in cancelOwnedRequest() }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            guard let ownedPopupID, !popupCoordinator.containsRequest(id: ownedPopupID) else { return }
            self.ownedPopupID = nil
            if isVisible, popupCoordinator.currentPopup == nil,
               let sourceID = returnFocusSourceID, sources.contains(where: { $0.id == sourceID }) {
                focusedSourceID = sourceID
            }
            returnFocusSourceID = nil
        }
        }
    }

    private func cancelOwnedRequest() {
        activeLinkID = nil
        if let ownedPopupID { popupCoordinator.cancelRequest(id: ownedPopupID) }
        ownedPopupID = nil
        returnFocusSourceID = nil
    }
    private func openSource(_ destination: URL, sourceID: String) {
        audioManager.play(.buttonSoftPop)
        let operation = UUID()
        activeLinkID = operation
        openURL(destination) { accepted in
            Task { @MainActor in
                guard isVisible, activeLinkID == operation, sources.contains(where: { $0.id == sourceID }) else { return }
                activeLinkID = nil
                guard !accepted else { return }
                let popupID = UUID()
                ownedPopupID = popupID
                returnFocusSourceID = sourceID
                popupCoordinator.request(FruitPopupRequest(id: popupID, character: .blueberry,
                    message: "this source link could not be opened. the original citation details remain on this page. you can copy the address to open it in another app.\n\n" + destination.absoluteString,
                    primaryAction: .init(label: "close") { popupCoordinator.dismissCurrent(reason: .programmatic) },
                    dismissBehavior: .explicitActionOnly, tone: .neutral, priority: .educational,
                    source: "source-link", deduplicationKey: "source-link-" + instanceID.uuidString,
                    surface: .tapedWhite))
            }
        }
    }

}
