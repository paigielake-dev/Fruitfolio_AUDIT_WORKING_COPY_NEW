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
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.fruitfolioModalBackgroundBlocked) private var ancestorBlocksBackground

    func body(content: Content) -> some View {
        // Nested editors may both own a confirmation. Only the outer active
        // host paints the treatment: otherwise radius, scale and tint compound.
        let paintsTreatment = isActive && !ancestorBlocksBackground
        let blocksBackground = isActive || ancestorBlocksBackground
        let motionReduced = reduceMotion || systemReduceMotion
        content
            .environment(\.fruitfolioModalBackgroundBlocked, blocksBackground)
            .blur(radius: paintsTreatment ? FruitfolioModalBlurSpec.radius : 0)
            .scaleEffect(paintsTreatment && !motionReduced ? FruitfolioModalBlurSpec.contentScale : 1.0)
            .overlay {
                if paintsTreatment {
                    DesignTokens.ColorToken.backgroundCream
                        .opacity(FruitfolioModalBlurSpec.dimOpacity)
                        .ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .allowsHitTesting(!blocksBackground)
            // Blurred modal backgrounds must not remain reachable by VoiceOver.
            .accessibilityHidden(blocksBackground)
            .animation(
                .easeOut(
                    duration: motionReduced
                        ? FruitfolioModalBlurSpec.reducedMotionDuration
                        : FruitfolioModalBlurSpec.animationDuration
                ),
                value: isActive
            )
    }
}

private struct FruitfolioModalBackgroundBlockedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var fruitfolioModalBackgroundBlocked: Bool {
        get { self[FruitfolioModalBackgroundBlockedKey.self] }
        set { self[FruitfolioModalBackgroundBlockedKey.self] = newValue }
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
