import Foundation

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

        .init(id: "lifebridge", title: "LifeBridge information", items: [
            .init(id: "lifebridge-information", question: "where can I find LifeBridge information?",
                  answer: "details not available in the approved library yet. open LifeBridge information for the founder-specified official destinations and reviewed source status.")
        ]),

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
                    answer: Prompt28RulesCopy.catches + " " + Prompt28RulesCopy.protection
                ),
                .init(id: "basket-results", question: "what does my result mean?", answer: Prompt28RulesCopy.results),
                .init(id: "basket-totals", question: "what counts toward the leaderboard?", answer: Prompt28RulesCopy.totals),
                .init(id: "basket-accessibility", question: "can I play without dragging?", answer: Prompt28RulesCopy.accessibleMode)
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

