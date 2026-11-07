import Foundation

enum Prompt07TourTarget: Hashable, Sendable {
    case ask
    case library
    case guideBuilder
    case cycle
    case fruitBasket
    case faq
}

enum Prompt07TourStep: Int, CaseIterable, Identifiable, Sendable {
    case ask = 1
    case library = 2
    case guideBuilder = 3
    case cycle = 4
    case fruitBasket = 5
    case ready = 6

    var id: Int { rawValue }

    var progressText: String {
        "\(rawValue) of 6"
    }

    var target: Prompt07TourTarget? {
        switch self {
        case .ask:
            return .ask
        case .library:
            return .library
        case .guideBuilder:
            return .guideBuilder
        case .cycle:
            return .cycle
        case .fruitBasket:
            return .fruitBasket
        case .ready:
            return nil
        }
    }

    var message: String { messageSpans.map(\.text).joined() }

    /// Editorial roles for these complete authored dialogue contexts only.
    /// No global word matching or changes to the founder's dialogue.
    var messageSpans: [FruitfolioSemanticSpan] {
        switch self {
        case .ask:
            return [.init(text: "got a question? start here > - < "),
                    .init(text: "i'll look through the     FruitsofLife.xo library for you.", emphasis: .anchorBold)]
        case .library:
            return [.init(text: "anything you love can be tucked into "),
                    .init(text: "your own little encyclopedia!", emphasis: .anchorBold)]
        case .guideBuilder:
            return [.init(text: "organize your saved pages into "),
                    .init(text: "chapters", emphasis: .anchorBold), .init(text: ", "),
                    .init(text: "notes", emphasis: .anchorBold), .init(text: ", "),
                    .init(text: "study guides", emphasis: .anchorBold), .init(text: ", "),
                    .init(text: "little handbooks", emphasis: .anchorBold),
                    .init(text: "… whatever works for you. :-)")]
        case .cycle:
            return [.init(text: "this is more than a period calendar.", emphasis: .anchorBold),
                    .init(text: " log what you know, and Fruitfolio will help you see the biology and patterns underneath your cycle.")]
        case .fruitBasket:
            return [.init(text: "and when you feel like playing… "),
                    .init(text: "come fill your fruit basket!", emphasis: .anchorBold)]
        case .ready:
            return [.init(text: "that’s it! explore wherever you’d like. <333")]
        }
    }
}

