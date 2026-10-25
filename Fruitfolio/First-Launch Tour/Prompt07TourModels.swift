import SwiftUI
import Combine

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

    @MainActor
    var character: FruitPopupCharacter {
        switch self {
        case .ask, .library, .guideBuilder, .ready:
            return .blueberry
        case .cycle:
            return .peach
        case .fruitBasket:
            return .strawberry
        }
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

    var message: String {
        switch self {
        case .ask:
            return "got a question? start here ( ´﹀` ) i’ll look through the FruitsofLife.xo library for you."
        case .library:
            return "anything you love can be tucked into your own little encyclopedia! ♡"
        case .guideBuilder:
            return "organize your saved pages into chapters, notes, study guides, little handbooks… whatever works for you. :-)"
        case .cycle:
            return "this is more than a period calendar. log what you know, and Fruitfolio will help you see the biology and patterns underneath your cycle."
        case .fruitBasket:
            return "and when you feel like playing… come fill your fruit basket! (〃⌒∇⌒)"
        case .ready:
            return "that’s it! explore wherever you’d like. ♡"
        }
    }
}

@MainActor
final class Prompt07TourController: ObservableObject {
    @Published private(set) var isTourActive = false
    @Published private(set) var currentStep: Prompt07TourStep = .ask

    func begin() {
        currentStep = .ask
        isTourActive = true
    }

    func next() {
        guard isTourActive else { return }
        guard let next = Prompt07TourStep(rawValue: currentStep.rawValue + 1) else {
            return
        }
        currentStep = next
    }

    func back() {
        guard isTourActive else { return }
        guard let previous = Prompt07TourStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        currentStep = previous
    }

    func end() {
        isTourActive = false
        currentStep = .ask
    }
}

struct Prompt07TargetFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Prompt07TourTarget: CGRect] = [:]

    static func reduce(
        value: inout [Prompt07TourTarget: CGRect],
        nextValue: () -> [Prompt07TourTarget: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct Prompt07TourTargetModifier: ViewModifier {
    let target: Prompt07TourTarget

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: Prompt07TargetFramePreferenceKey.self,
                        value: [
                            target: proxy.frame(in: .named("Prompt07HubSpace"))
                        ]
                    )
                }
            }
    }
}

extension View {
    func prompt07TourTarget(_ target: Prompt07TourTarget) -> some View {
        modifier(Prompt07TourTargetModifier(target: target))
    }
}
