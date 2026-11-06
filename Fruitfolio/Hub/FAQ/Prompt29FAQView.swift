import SwiftUI

struct Prompt29FAQView: View {
    let onBack: () -> Void

    @State private var expanded: Set<String> = []

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Prompt29FAQCatalog.sections) { section in
                        Prompt29FAQSectionCard(
                            section: section,
                            expanded: $expanded
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 42)
                .frame(maxWidth: DesignTokens.Layout.compactReadingMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .top, spacing: 0) {
                FruitfolioDecoratedRouteHeader(palette: .faq) {
                    Prompt12RouteHeader(title: "FAQ", subtitle: "you’ve got questions. we’ve got answers. ♡",
                                        assetName: nil, onBack: onBack)
                }
                .padding(.horizontal, 20)
                .background(DesignTokens.ColorToken.backgroundCream)
            }

        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct Prompt29FAQSectionCard: View {
    let section: Prompt29FAQSection
    @Binding var expanded: Set<String>
    @State private var showLifeBridge = false
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(settings.localized(section.title))
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 16,
                        relativeTo: .headline
                    )
                )
                .fontWeight(.bold)

            ForEach(section.items) { item in
                let isExpanded = expanded.contains(item.id)
                Button {
                    audioManager.play(.buttonSoftPop)
                    if isExpanded { expanded.remove(item.id) } else { expanded.insert(item.id) }
                } label: {
                    HStack(spacing: 10) {
                        Text(settings.localized(item.question))
                            .fontWeight(.regular)
                            .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image("control_next")
                            .resizable().scaledToFit().frame(width: 22, height: 22)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .accessibilityHidden(true)
                    }.frame(minHeight: 44)
                }
                .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                .accessibilityValue(isExpanded ? "expanded" : "collapsed")
                .accessibilityIdentifier("faq.question.\(item.id)")
                if isExpanded {
                    FruitfolioTranslatedText(source: item.answer,
                                             font: .custom("Chalkboard SE", size: 12.5, relativeTo: .body), serious: true)
                        .font(.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    if item.id == "lifebridge-information" {
                        WatercolorSecondaryButton(label: "open LifeBridge information") { showLifeBridge = true }
                    }
                }
            }
        }
        .sheet(isPresented: $showLifeBridge) {
            FruitfolioLifeBridgeInformationView(onBack: { showLifeBridge = false })
        }
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .padding(16)
        .background(
            DesignTokens.ColorToken.backgroundCream.opacity(0.88),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .stroke(
                DesignTokens.ColorToken.primaryBurgundy.opacity(0.13),
                lineWidth: 1
            )
        }
    }

    private func expansionBinding(
        for itemID: String
    ) -> Binding<Bool> {
        Binding(
            get: {
                expanded.contains(itemID)
            },
            set: {
                if $0 {
                    expanded.insert(itemID)
                } else {
                    expanded.remove(itemID)
                }
            }
        )
    }
}
