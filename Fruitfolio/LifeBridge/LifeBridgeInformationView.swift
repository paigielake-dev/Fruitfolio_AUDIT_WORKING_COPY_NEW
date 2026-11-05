import SwiftUI

struct FruitfolioLifeBridgeInformationView: View {
    let onBack: () -> Void
    private let approved = FruitfolioLifeBridgeInformation.load()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackControl(action: onBack)
                Text("LifeBridge information").font(.title2).bold().accessibilityAddTraits(.isHeader)
                if let approved {
                    ForEach(approved.snapshots, id: \.id) { snapshot in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(verbatim: snapshot.title).bold()
                            FruitfolioTranslatedText(source: snapshot.approvedText,
                                                     protectedLiterals: [snapshot.sourceURL.absoluteString])
                            Text(verbatim: snapshot.sourceURL.absoluteString).font(.caption)
                            Text("retrieved \(snapshot.retrievedAt.formatted(date: .abbreviated, time: .omitted))")
                            Text("reviewed \(snapshot.reviewedAt.formatted(date: .abbreviated, time: .omitted)) · \(snapshot.version)")
                        }
                    }
                    if let disclosure = approved.relationshipDisclosure { Text(verbatim: disclosure) }
                    if let application = approved.officialApplicationURL {
                        Link("official application — opens an external website", destination: application)
                    }
                } else {
                    Text(LocalizedStringKey(FruitfolioLifeBridgeInformation.missingContent))
                        .accessibilityIdentifier("lifebridge.awaitingVerifiedContent")
                    Text("organization-specific services, eligibility, process, contact details, and founder/referral context await reviewed source snapshots from both named websites.")
                }
                Text("current eligibility, application, and contact information should be checked on the official website. these links open external websites only when you choose them; local health information is not attached.")
                if let official = FruitfolioLifeBridgeInformation.officialURL {
                    Link("LifeBridge Surrogacy official website", destination: official)
                }
                if let founder = FruitfolioLifeBridgeInformation.founderURL {
                    Link("FruitsofLife.xo founder website", destination: founder)
                }
            }
            .padding(20)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .accessibilityIdentifier("lifebridge.information")
    }
}
