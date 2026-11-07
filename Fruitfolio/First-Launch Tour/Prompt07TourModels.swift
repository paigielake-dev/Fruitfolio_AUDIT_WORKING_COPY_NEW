import SwiftUI
import Combine

extension Prompt07TourStep {
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

/// Delayed invitation work is valid only while the Hub is the active screen.
enum Prompt07InvitationEligibility {
    static func allows(route: FruitfolioRoute, isActive: Bool, tutorialCompleted: Bool) -> Bool {
        route == .hub && isActive && !tutorialCompleted
    }
}
