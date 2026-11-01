import SwiftUI

/// Canonical blur for every non-tour modal surface. The Hub first-launch tour
/// intentionally keeps its dedicated tour blur and does not use this spec.
enum FruitfolioModalBlurSpec {
    static let radius: CGFloat = 8
    static let dimOpacity: Double = 0.14
    static let contentScale: CGFloat = 0.985
    static let animationDuration: TimeInterval = 0.20
    static let reducedMotionDuration: TimeInterval = 0.12
}

struct FruitfolioModalBlurModifier: ViewModifier {
    let isActive: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .blur(radius: isActive ? FruitfolioModalBlurSpec.radius : 0)
            .scaleEffect(isActive ? FruitfolioModalBlurSpec.contentScale : 1.0)
            .overlay {
                if isActive {
                    DesignTokens.ColorToken.backgroundCream
                        .opacity(FruitfolioModalBlurSpec.dimOpacity)
                        .ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .allowsHitTesting(!isActive)
            // Blurred modal backgrounds must not remain reachable by VoiceOver.
            .accessibilityHidden(isActive)
            .animation(
                .easeOut(
                    duration: reduceMotion
                        ? FruitfolioModalBlurSpec.reducedMotionDuration
                        : FruitfolioModalBlurSpec.animationDuration
                ),
                value: isActive
            )
    }
}

extension View {
    func fruitfolioModalBlur(
        active: Bool,
        reduceMotion: Bool
    ) -> some View {
        modifier(
            FruitfolioModalBlurModifier(
                isActive: active,
                reduceMotion: reduceMotion
            )
        )
    }
}
