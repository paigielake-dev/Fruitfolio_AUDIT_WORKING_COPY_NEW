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

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        Prompt12RouteHeader(
                            title: "FAQ",
                            subtitle: "you’ve got questions. we’ve got answers. ♡",
                            assetName: nil,
                            onBack: onBack
                        )

                        HStack(spacing: -7) {
                            FruitfolioImage(id: .fruitbasket_orange)
                                .frame(width: 46, height: 46)

                            FruitfolioImage(id: .fruitbasket_pear)
                                .frame(width: 46, height: 46)

                            FruitfolioImage(id: .fruitbasket_lemon)
                                .frame(width: 46, height: 46)

                            FruitfolioImage(id: .fruitbasket_star)
                                .frame(width: 22, height: 22)
                                .offset(y: -13)
                        }
                        .padding(.top, 2)
                        .padding(.trailing, 2)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)

                        FruitfolioImage(id: .decor_sparkles_1)
                            .frame(width: 54, height: 54)
                            .rotationEffect(.degrees(-18))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .offset(x: 111, y: 5)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }

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
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct Prompt29FAQSectionCard: View {
    let section: Prompt29FAQSection
    @Binding var expanded: Set<String>

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
                }.buttonStyle(.plain)
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
