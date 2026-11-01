import SwiftUI

struct LifeBridgeInformationView: View {
    let onBack: () -> Void
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var motion: MotionPreferences
    @State private var pending: LifeBridgeInformation.Destination?
    @State private var linkFailed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Prompt12RouteHeader(title: "LifeBridge information", subtitle: "surrogacy information and support links", assetName: nil, onBack: onBack)
                Text("this directory is available to anyone. viewing it does not change your health context, cycle predictions, or saved information.")
                Text("verified local content is still needed from both the LifeBridge official site and FruitsofLife.xo. current organization details, eligibility, application information, and any founder referral or commission relationship have not been verified for this bundled edition.")
                    .accessibilityIdentifier("lifebridge.contentAvailability")
                ForEach(LifeBridgeInformation.ContentSlot.allCases) { slot in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey(slot.title)).font(.headline).accessibilityAddTraits(.isHeader)
                        Text(LocalizedStringKey(LifeBridgeInformation.unavailable))
                            .accessibilityIdentifier("lifebridge.slot." + slot.id)
                    }
                }
                Text("independent education and organization information are different. medical and scientific explanations in Ask must still use the approved Research Library. this directory is not individual medical, legal, financial, or eligibility advice.")
                Text("these are the website destinations named in Prompt 1B. links require internet access. check the official site for current information. no application or referral link is supplied without verification.")
                ForEach(LifeBridgeInformation.Destination.allCases) { destination in
                    FruitfolioControlPillButton(label: destination.title) { pending = destination }
                        .accessibilityIdentifier("lifebridge.link." + destination.id)
                }
                Text("source directory version: " + LifeBridgeInformation.version)
                    .font(.caption)
            }
            .padding(20)
            .frame(maxWidth: DesignTokens.Layout.compactReadingMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .accessibilityIdentifier("lifebridge.information")
        .fruitfolioModalBlur(active: pending != nil || linkFailed, reduceMotion: motion.reduceMotionActive)
        .overlay {
            if let destination = pending {
                Prompt12ConfirmationPopup(assetName: "popup_info", title: "leave Fruitfolio?",
                    message: "open \(destination.title) in an external app? Fruitfolio sends no health context, cycle logs, Ask history, or profile information. the external website has its own privacy practices. no verified founder referral or commission details are available in this edition.",
                    primaryLabel: "open website", secondaryLabel: "stay in Fruitfolio", destructiveLabel: nil,
                    primaryAction: {
                        pending = nil
                        openURL(destination.url) { accepted in if !accepted { linkFailed = true } }
                    }, secondaryAction: { pending = nil }, destructiveAction: nil)
            } else if linkFailed {
                Prompt12ConfirmationPopup(assetName: "popup_info", title: "website could not open",
                    message: "you can keep reading this local directory. an internet connection and an app that can open websites are needed for external pages.",
                    primaryLabel: "got it", secondaryLabel: nil, destructiveLabel: nil,
                    primaryAction: { linkFailed = false }, secondaryAction: nil, destructiveAction: nil)
            }
        }
    }
}
