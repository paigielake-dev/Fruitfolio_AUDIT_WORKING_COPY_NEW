import SwiftUI

/// Fruitfolio's shared tactile button animation.
/// Gives buttons a visible squish-and-spring response that pairs with the soft bubble-pop SFX.
struct CutePopButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.fruitfolioReduceMotion) private var appReduceMotion
    let reduceMotion: Bool

    init(reduceMotion: Bool = false) {
        self.reduceMotion = reduceMotion
    }

    func makeBody(configuration: Configuration) -> some View {
        let reduceMotion = self.reduceMotion || systemReduceMotion || appReduceMotion
        return configuration.label
            .scaleEffect(
                reduceMotion
                    ? 1.0
                    : (configuration.isPressed ? 0.88 : 1.0)
            )
            .offset(
                y: reduceMotion
                    ? 0
                    : (configuration.isPressed ? 5 : 0)
            )
            .rotationEffect(
                .degrees(
                    reduceMotion
                        ? 0
                        : (configuration.isPressed ? -1.2 : 0)
                )
            )
            .brightness(
                configuration.isPressed
                    ? -0.04
                    : 0
            )
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.08)
                    : .spring(
                        response: 0.20,
                        dampingFraction: 0.38,
                        blendDuration: 0
                    ),
                value: configuration.isPressed
            )
    }
}

private struct FruitfolioReduceMotionKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var fruitfolioReduceMotion: Bool {
        get { self[FruitfolioReduceMotionKey.self] }
        set { self[FruitfolioReduceMotionKey.self] = newValue }
    }
}
