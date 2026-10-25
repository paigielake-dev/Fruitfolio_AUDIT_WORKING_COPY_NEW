import SwiftUI

enum FruitfolioArtScale: Sendable {
    case tinyFleck
    case smallDecoration
    case tinyFunctionalIcon
    case normalFunctionalIllustration
    case fruitCharacter
    case mediumIllustration
    case majorBiologyIllustration
    case heroIllustration
    case bookEnvironment

    var range: ClosedRange<CGFloat> {
        switch self {
        case .tinyFleck: return DesignTokens.Layout.tinyFleck
        case .smallDecoration: return DesignTokens.Layout.smallDecoration
        case .tinyFunctionalIcon: return DesignTokens.Layout.tinyFunctionalIcon
        case .normalFunctionalIllustration: return DesignTokens.Layout.normalFunctionalIllustration
        case .fruitCharacter: return DesignTokens.Layout.fruitCharacter
        case .mediumIllustration: return DesignTokens.Layout.mediumIllustration
        case .majorBiologyIllustration: return DesignTokens.Layout.majorBiologyIllustration
        case .heroIllustration: return DesignTokens.Layout.heroIllustration
        case .bookEnvironment: return DesignTokens.Layout.bookEnvironment
        }
    }

    func width(for availableWidth: CGFloat, bias: CGFloat = 0.5) -> CGFloat {
        let clampedBias = min(max(bias, 0), 1)
        let fraction = range.lowerBound + ((range.upperBound - range.lowerBound) * clampedBias)
        return availableWidth * fraction
    }
}

enum FruitfolioLayoutMetrics {
    static func horizontalMargin(for width: CGFloat) -> CGFloat {
        if width <= 340 { return DesignTokens.Layout.minimumHorizontalMargin }
        if width <= DesignTokens.ReferenceCanvas.width { return 20 }
        if width < 430 { return 22 }
        return 24
    }

    static func readingWidth(for width: CGFloat) -> CGFloat {
        let margin = horizontalMargin(for: width)
        return min(width - (margin * 2), DesignTokens.Layout.standardReadingMaxWidth)
    }

    static func proMaxWhitespaceBonus(for width: CGFloat) -> CGFloat {
        max(0, min(20, (width - DesignTokens.ReferenceCanvas.width) * 0.20))
    }
}

struct FruitfolioSafeContent<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let margin = FruitfolioLayoutMetrics.horizontalMargin(for: proxy.size.width)
            ScrollView {
                content
                    .frame(maxWidth: FruitfolioLayoutMetrics.readingWidth(for: proxy.size.width), alignment: .leading)
                    .padding(.horizontal, margin)
                    .padding(.top, DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxl)
                    .frame(maxWidth: .infinity)
            }
            .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        }
    }
}

struct FruitfolioArtwork: View {
    let id: FruitfolioAssetID
    let scale: FruitfolioArtScale
    var bias: CGFloat = 0.5
    var accessibilityLabel: String? = nil
    var decorative: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let width = scale.width(for: proxy.size.width, bias: bias)
            FruitfolioAssetLoader.image(id)
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(decorative)
                .accessibilityLabel(Text(accessibilityLabel ?? ""))
        }
    }
}

struct MinimumHitTarget: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: DesignTokens.Layout.minimumHitTarget,
                   minHeight: DesignTokens.Layout.minimumHitTarget)
            .contentShape(Rectangle())
    }
}

extension View {
    func fruitfolioMinimumHitTarget() -> some View {
        modifier(MinimumHitTarget())
    }
}
