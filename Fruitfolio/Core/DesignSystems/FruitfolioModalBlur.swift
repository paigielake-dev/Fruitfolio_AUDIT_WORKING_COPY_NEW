import SwiftUI

/// Canonical blur for every non-tour modal surface. The Hub first-launch tour
/// intentionally keeps its dedicated tour blur and does not use this spec.
enum FruitfolioModalBlurSpec {
    static let radius: CGFloat = 8
    static let dimOpacity: Double = 0.14
    static let contentScale: CGFloat = 0.985
    static let animationDuration: TimeInterval = 0.20
    static let reducedMotionDuration: TimeInterval = 0.12

    static func scale(active: Bool, reduceMotion: Bool) -> CGFloat {
        active && !reduceMotion ? contentScale : 1
    }
}

/// Visual backdrop shared by non-Hub-tour modal families. Each caller retains
/// its existing outside-tap policy; this view never dismisses a presentation.
struct FruitfolioModalBackdrop: View {
    var body: some View {
        Color.black.opacity(FruitfolioModalBlurSpec.dimOpacity)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

struct FruitfolioModalBlurModifier: ViewModifier {
    let isActive: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .blur(radius: isActive ? FruitfolioModalBlurSpec.radius : 0)
            .scaleEffect(FruitfolioModalBlurSpec.scale(active: isActive, reduceMotion: reduceMotion))
            .accessibilityHidden(isActive)
            .allowsHitTesting(!isActive)
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
