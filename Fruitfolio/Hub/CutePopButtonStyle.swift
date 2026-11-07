import SwiftUI

/// Fruitfolio's shared tactile button animation.
/// Gives buttons a visible squish-and-spring response that pairs with the soft bubble-pop SFX.
struct CutePopButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    init(reduceMotion: Bool = false) {
        self.reduceMotion = reduceMotion
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(FruitfolioButtonPopEffect(isPressed: configuration.isPressed, reduceMotion: reduceMotion))
    }
}

// This is a derived environment value, not another persisted motion preference.
// It lets native/custom styles honor the shell's app override without requiring
// an environment object in standalone controls or previews.
private struct FruitfolioAppReduceMotionKey: EnvironmentKey {
    static let defaultValue = false
}
extension EnvironmentValues {
    var fruitfolioAppReduceMotion: Bool {
        get { self[FruitfolioAppReduceMotionKey.self] }
        set { self[FruitfolioAppReduceMotionKey.self] = newValue }
    }
}

struct FruitfolioButtonPopEffect: ViewModifier {
    let isPressed: Bool
    var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.fruitfolioAppReduceMotion) private var appReduceMotion
    private var reduced: Bool { reduceMotion || systemReduceMotion || appReduceMotion }

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                reduced
                    ? 1.0
                    : (isPressed ? 0.88 : 1.0)
            )
            .offset(
                y: reduced
                    ? 0
                    : (isPressed ? 5 : 0)
            )
            .rotationEffect(
                .degrees(
                    reduced
                        ? 0
                        : (isPressed ? -1.2 : 0)
                )
            )
            .brightness(
                isPressed
                    ? -0.04
                    : 0
            )
            .animation(
                reduced
                    ? .easeOut(duration: 0.08)
                    : .spring(
                        response: 0.20,
                        dampingFraction: 0.38,
                        blendDuration: 0
                    ),
                value: isPressed
            )
    }
}
