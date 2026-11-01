import SwiftUI

struct Prompt29FAQItem: Identifiable, Hashable, Sendable {
    let id: String
    let question: String
    let answer: String
}

struct Prompt29FAQSection: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let items: [Prompt29FAQItem]
}

enum Prompt29FAQCatalog {
    static let sections: [Prompt29FAQSection] = [
        .init(
            id: "about",
            title: "about Fruitfolio",
            items: [
                .init(
                    id: "about-1",
                    question: "what is Fruitfolio?",
                    answer: "Fruitfolio is an educational women’s-health encyclopedia, personal library, cycle tracker, and little learning world by FruitsofLife.xo."
                ),
                .init(
                    id: "about-2",
                    question: "is Fruitfolio medical care?",
                    answer: "no. Fruitfolio is educational and does not replace a qualified healthcare professional."
                )
            ]
        ),

        .init(
            id: "encyclopedia",
            title: "encyclopedia",
            items: [
                .init(
                    id: "ask-1",
                    question: "where do Ask answers come from?",
                    answer: "Ask is limited to Fruitfolio’s approved Research Library and verified source records. unsupported questions stay unsupported rather than being filled from model memory."
                ),
                .init(
                    id: "ask-2",
                    question: "can I save an answer?",
                    answer: "yes. supported Ask content can be saved to My Encyclopedias with its source provenance preserved."
                )
            ]
        ),

        .init(
            id: "cycle",
            title: "cycle tracker",
            items: [
                .init(
                    id: "cycle-1",
                    question: "are cycle predictions guaranteed?",
                    answer: "no. predictions and fertile-window estimates are estimates, not confirmations or contraceptive guarantees."
                ),
                .init(
                    id: "cycle-2",
                    question: "does Fruitfolio diagnose me?",
                    answer: "no. recorded, calculated, estimated, predicted, and educational information stay explicitly distinct."
                )
            ]
        ),

        .init(
            id: "basket",
            title: "Fruit Basket",
            items: [
                .init(
                    id: "basket-1",
                    question: "how does catching work?",
                    answer: "catch 10 starred fruits to fill your basket. unstarred fruit can pass, and missing a starred fruit is okay—another one will come along."
                )
            ]
        ),

        .init(
            id: "privacy",
            title: "privacy",
            items: [
                .init(
                    id: "privacy-1",
                    question: "is my health data used for advertising?",
                    answer: "Fruitfolio’s privacy architecture treats reproductive and health information as sensitive product data, not advertising analytics data."
                )
            ]
        ),

        .init(
            id: "purchase",
            title: "purchase",
            items: [
                .init(
                    id: "purchase-1",
                    question: "is there a subscription?",
                    answer: "Fruitfolio is designed as a $9.99 one-time App Store purchase. ordinary local AI generation must not create a per-question fee for you or Fruitfolio."
                )
            ]
        ),

        .init(
            id: "brand",
            title: "FruitsofLife.xo",
            items: [
                .init(
                    id: "brand-1",
                    question: "who made Fruitfolio?",
                    answer: "Fruitfolio is by FruitsofLife.xo."
                )
            ]
        )
    ]
}

struct Prompt29FAQView: View {
    let onBack: () -> Void

    @State private var expanded: Set<String> = []
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Prompt29FAQDecoration().frame(height: 130).padding(.horizontal, 20)
                }
                ScrollView {
                VStack(spacing: 16) {
                    Prompt12RouteHeader(
                        title: "FAQ",
                        subtitle: "you’ve got questions. we’ve got answers. ♡",
                        assetName: nil,
                        onBack: onBack
                    )

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
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
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
                        Text(item.question)
                            .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image("control_next")
                            .resizable().scaledToFit().frame(width: 22, height: 22)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .accessibilityHidden(true)
                    }.frame(minHeight: 44)
                }.buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                if isExpanded {
                    Text(item.answer)
                        .font(.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
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

private struct Prompt29FAQDecoration: View {
    private let assets: [(FruitfolioAssetID, FruitfolioDecorativeAnchor, ClosedRange<CGFloat>)] = [
        (.decor_fluffy_cloud, .topTrailing, 0.30...0.44),
        (.decor_grass, .bottomLeading, 0.24...0.30),
        (.decor_sparkles_1, .bottomTrailing, 0.12...0.16)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(assets.indices, id: \.self) { index in
                    let item = assets[index]
                    if let image = try? FruitfolioAssetLoader.uiImage(item.0) {
                        let placement = FruitfolioDecorativeArtLayout.placement(
                            intrinsicSize: image.size,
                            roleFraction: item.2,
                            anchor: item.1,
                            container: CGRect(origin: .zero, size: geometry.size),
                            safeInsets: EdgeInsets(),
                            protectedRegions: []
                        )
                        if placement.isVisible {
                            Image(uiImage: image).resizable().scaledToFit()
                                .frame(width: placement.frame.width, height: placement.frame.height)
                                .position(x: placement.frame.midX, y: placement.frame.midY)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
