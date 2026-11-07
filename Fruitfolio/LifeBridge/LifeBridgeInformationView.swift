import SwiftUI
import UIKit

struct FruitfolioLifeBridgeInformationView: View {
    let onBack: () -> Void
    @State private var approved: FruitfolioLifeBridgeContent?
    @State private var loading = true
    @State private var viewIsVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    private var canInteract: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active && popupCoordinator.currentPopup == nil
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackControl(action: { guard canInteract else { return }; onBack() })
                FruitfolioFixedText(source: "LifeBridge information", font: .title2.bold(), serious: true).accessibilityAddTraits(.isHeader)
                if let approved {
                    ForEach(approved.orderedSnapshots, id: \.id) { snapshot in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(verbatim: snapshot.title).bold()
                            FruitfolioTranslatedText(source: snapshot.approvedText,
                                                     protectedLiterals: [snapshot.sourceURL.absoluteString] + FruitfolioLifeBridgeInformation.protectedNames(in: snapshot.approvedText), serious: true)
                            Text(verbatim: snapshot.sourceURL.absoluteString).font(.caption)
                            HStack(alignment: .firstTextBaseline) {
                                FruitfolioFixedText(source: "retrieved", serious: true)
                                Text(snapshot.retrievedAt, style: .date)
                            }.accessibilityElement(children: .combine)
                            HStack(alignment: .firstTextBaseline) {
                                FruitfolioFixedText(source: "reviewed", serious: true)
                                Text(snapshot.reviewedAt, style: .date)
                                Text(verbatim: "· " + snapshot.version)
                            }.accessibilityElement(children: .combine)
                        }
                    }
                    if let differences = approved.sourceDiscrepancies, !differences.isEmpty {
                        FruitfolioFixedText(source: "source differences flagged for founder review", serious: true)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(Array(differences.enumerated()), id: \.offset) { _, text in
                            FruitfolioTranslatedText(source: text, protectedLiterals: FruitfolioLifeBridgeInformation.protectedNames(in: text), serious: true)
                        }
                    }
                    FruitfolioFixedText(source: "for organization-specific details, follow LifeBridge’s official source. founder context is shown separately.",
                        protectedLiterals: ["LifeBridge"], serious: true)
                    if let disclosure = approved.relationshipDisclosure { FruitfolioTranslatedText(source: disclosure, protectedLiterals: FruitfolioLifeBridgeInformation.protectedNames(in: disclosure), serious: true) }
                    if let application = approved.officialApplicationURL {
                        Link(destination: application) { FruitfolioFixedText(source: "official application — opens an external website", serious: true) }
                        .disabled(!canInteract)
                    }
                } else if loading {
                    ProgressView { FruitfolioFixedText(source: "loading information", serious: true) }
                } else {
                    FruitfolioFixedText(source: FruitfolioLifeBridgeInformation.missingContent, serious: true)
                        .accessibilityIdentifier("lifebridge.awaitingVerifiedContent")
                    FruitfolioTranslatedText(source: "organization-specific services, eligibility, process, contact details, and founder/referral context await reviewed source snapshots from both named websites.", serious: true)
                }
                FruitfolioTranslatedText(source: "current eligibility, application, and contact information should be checked on the official website. these links open external websites only when you choose them; local health information is not attached.", serious: true)
                if let official = FruitfolioLifeBridgeInformation.officialURL {
                    Link(destination: official) { FruitfolioFixedText(source: "LifeBridge Surrogacy official website", protectedLiterals: ["LifeBridge Surrogacy"], serious: true) }
                        .disabled(!canInteract)
                }
                if let founder = FruitfolioLifeBridgeInformation.founderURL {
                    Link(destination: founder) { FruitfolioFixedText(source: "FruitsofLife.xo founder website", protectedLiterals: ["FruitsofLife.xo"], serious: true) }
                        .disabled(!canInteract)
                }
                if let instagram = FruitfolioLifeBridgeInformation.founderInstagramURL {
                    Link(destination: instagram) {
                        FruitfolioFixedText(source: "FruitsofLife.xo on Instagram — opens an external website",
                            protectedLiterals: ["FruitsofLife.xo", "Instagram"], serious: true)
                    }
                    .disabled(!canInteract)
                    .accessibilityIdentifier("lifebridge.founderInstagram")
                    FruitfolioFixedText(source: "FruitsofLife.xo’s account is a first-party source about the brand. medical or scientific claims still require approved scientific sources.",
                        protectedLiterals: ["FruitsofLife.xo"], serious: true)
                }
            }
            .padding(20)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .task {
            do {
                let content = try await FruitfolioResearchPackageStore.shared.lifeBridgeContent()
                guard !Task.isCancelled else { return }
                approved = content
            } catch {
                guard !Task.isCancelled else { return }
                approved = nil
            }
            loading = false
        }
        .onAppear { viewIsVisible = true }
        .onDisappear { viewIsVisible = false }
        .accessibilityIdentifier("lifebridge.information")
    }
}
