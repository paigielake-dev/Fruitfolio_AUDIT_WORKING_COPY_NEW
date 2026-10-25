import SwiftUI
import UIKit

enum FruitfolioTextRole: Sendable {
    case majorTitle
    case screenTitle
    case sectionHeading
    case button
    case body
    case secondary
    case metadata
}

enum FruitfolioTypography {
    static func font(for role: FruitfolioTextRole) -> Font {
        switch role {
        case .majorTitle:
            return .system(size: 29, weight: .semibold, design: .serif)
        case .screenTitle:
            return .system(size: 24, weight: .semibold, design: .serif)
        case .sectionHeading:
            return .system(size: 19, weight: .semibold, design: .serif)
        case .button:
            return .system(size: 16, weight: .semibold, design: .rounded)
        case .body:
            return .system(size: 16, weight: .regular, design: .serif)
        case .secondary:
            return .system(size: 13, weight: .regular, design: .serif)
        case .metadata:
            return .system(size: 11.5, weight: .regular, design: .rounded)
        }
    }

    // Prompt-wide long-press labels explicitly require Comic Sans MS.
    // No fallback is supplied here: absence remains a visible dependency instead of silent substitution.
    static var comicSansMSAvailable: Bool {
        UIFont(name: "Comic Sans MS", size: 13) != nil
    }

    static func comicSansMicroLabelFont(size: CGFloat = 13) -> Font? {
        guard comicSansMSAvailable else { return nil }
        return .custom("Comic Sans MS", size: size, relativeTo: .caption)
    }
}

struct FruitfolioTextStyle: ViewModifier {
    let role: FruitfolioTextRole
    let secondary: Bool

    func body(content: Content) -> some View {
        content
            .font(FruitfolioTypography.font(for: role))
            .foregroundStyle(
                secondary
                ? DesignTokens.ColorToken.secondaryBurgundy
                : DesignTokens.ColorToken.primaryBurgundy
            )
    }
}

extension View {
    func fruitfolioText(_ role: FruitfolioTextRole, secondary: Bool = false) -> some View {
        modifier(FruitfolioTextStyle(role: role, secondary: secondary))
    }
}
