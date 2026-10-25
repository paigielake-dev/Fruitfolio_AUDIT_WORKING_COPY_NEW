import SwiftUI

enum FruitfolioMotionCategory: String, CaseIterable, Sendable {
    case micro
    case component
    case storybook
    case celebration

    var defaultDuration: Double {
        switch self {
        case .micro: return DesignTokens.Motion.microDefault
        case .component: return DesignTokens.Motion.componentDefault
        case .storybook: return DesignTokens.Motion.storybookDefault
        case .celebration: return DesignTokens.Motion.celebrationDefault
        }
    }

    var allowedRange: ClosedRange<Double> {
        switch self {
        case .micro: return DesignTokens.Motion.micro
        case .component: return DesignTokens.Motion.component
        case .storybook: return DesignTokens.Motion.storybook
        case .celebration: return DesignTokens.Motion.celebration
        }
    }
}

enum FruitfolioMotion {
    static func animation(
        _ category: FruitfolioMotionCategory,
        reduceMotion: Bool
    ) -> Animation? {
        if reduceMotion {
            switch category {
            case .micro:
                return .easeOut(duration: 0.08)
            case .component, .storybook, .celebration:
                return .easeInOut(duration: 0.16)
            }
        }

        switch category {
        case .micro:
            return .easeOut(duration: category.defaultDuration)
        case .component:
            return .easeInOut(duration: category.defaultDuration)
        case .storybook:
            return .easeInOut(duration: category.defaultDuration)
        case .celebration:
            return .easeInOut(duration: category.defaultDuration)
        }
    }
}
