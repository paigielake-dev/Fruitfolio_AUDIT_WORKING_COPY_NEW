import SwiftUI

@MainActor
enum FruitPopupCharacter: String, CaseIterable, Sendable {
    case strawberry
    case blueberry
    case peach

    var assetID: FruitfolioAssetID {
        switch self {
        case .strawberry: return .fruit_strawberry_silly
        case .blueberry: return .fruit_blueberry_friendly
        case .peach: return .fruit_peach_soft
        }
    }

    var semanticRole: String {
        switch self {
        case .strawberry: return "celebration"
        case .blueberry: return "knowledge"
        case .peach: return "gentleness"
        }
    }

    var entranceDuration: Double {
        switch self {
        case .strawberry: return 0.22
        case .blueberry: return 0.25
        case .peach: return 0.28
        }
    }
}

enum FruitPopupTone: String, CaseIterable, Sendable {
    case informational, educational, celebratory, gentle, cautionary, success, neutral
}

enum FruitPopupPositionPreference: String, CaseIterable, Sendable {
    case automatic, top, upperLeading, upperTrailing, centerLeading, centerTrailing, lowerLeading, lowerTrailing, bottom
}

enum FruitPopupPriority: Int, Comparable, Sendable {
    case flavor = 0
    case success = 10
    case educational = 20
    case sensitive = 30

    static func < (lhs: FruitPopupPriority, rhs: FruitPopupPriority) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum FruitPopupDismissBehavior: Equatable, Sendable {
    case explicitActionOnly
    case tapOutside
    case tapPopup
    case timed(seconds: Double)
    case navigationTriggered
    case programmatic
    case persistentUntilAcknowledged
}

struct FruitPopupAction: Identifiable {
    let id = UUID()
    let label: String
    let accessibilityLabel: String?
    let handler: @MainActor () -> Void

    init(label: String, accessibilityLabel: String? = nil, handler: @escaping @MainActor () -> Void) {
        self.label = label
        self.accessibilityLabel = accessibilityLabel
        self.handler = handler
    }
}

struct FruitPopupRequest: Identifiable {
    let id: UUID
    let character: FruitPopupCharacter
    let message: String
    let primaryAction: FruitPopupAction?
    let secondaryAction: FruitPopupAction?
    let positionPreference: FruitPopupPositionPreference
    let dismissBehavior: FruitPopupDismissBehavior
    let tone: FruitPopupTone
    let priority: FruitPopupPriority
    let source: String?
    let deduplicationKey: String?
    let analyticsIdentifier: String?

    init(
        id: UUID = UUID(),
        character: FruitPopupCharacter,
        message: String,
        primaryAction: FruitPopupAction? = nil,
        secondaryAction: FruitPopupAction? = nil,
        positionPreference: FruitPopupPositionPreference = .automatic,
        dismissBehavior: FruitPopupDismissBehavior = .tapOutside,
        tone: FruitPopupTone = .neutral,
        priority: FruitPopupPriority = .educational,
        source: String? = nil,
        deduplicationKey: String? = nil,
        analyticsIdentifier: String? = nil
    ) {
        self.id = id
        self.character = character
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.positionPreference = positionPreference
        self.dismissBehavior = dismissBehavior
        self.tone = tone
        self.priority = priority
        self.source = source
        self.deduplicationKey = deduplicationKey
        self.analyticsIdentifier = analyticsIdentifier
    }
}
