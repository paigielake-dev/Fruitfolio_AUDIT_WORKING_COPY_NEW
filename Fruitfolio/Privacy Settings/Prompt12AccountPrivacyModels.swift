import Foundation

enum Prompt12OwnershipState: String, Codable, Equatable, Sendable {
    case purchased
    case validating
    case validationUnavailable
    case unknown

    var displayTitle: String {
        switch self {
        case .purchased:
            return "Fruitfolio purchased ♡"
        case .validating:
            return "checking ownership"
        case .validationUnavailable:
            return "ownership check unavailable"
        case .unknown:
            return "ownership not checked yet"
        }
    }

    var displayDetail: String {
        switch self {
        case .purchased:
            return "$9.99 one-time purchase. no subscription."
        case .validating:
            return "Fruitfolio is checking the storefront record quietly."
        case .validationUnavailable:
            return "you can keep using Fruitfolio while storefront validation is unavailable."
        case .unknown:
            return "Fruitfolio is designed as a paid app you already own after download."
        }
    }
}

enum Prompt12AuthenticationState: String, Codable, Equatable, Sendable {
    case signedOut
    case signingIn
    case signedIn
    case signInFailed
    case sessionExpired
    case signingOut
    case deletingAccount
    case accountDeleted

    var isSignedIn: Bool {
        self == .signedIn
    }
}

enum Prompt12SyncState: String, Codable, Equatable, Sendable {
    case localOnly
    case syncing
    case synced
    case pendingLocalChanges
    case failed
    case unavailable

    var displayText: String {
        switch self {
        case .localOnly:
            return "stored on this device"
        case .syncing:
            return "syncing…"
        case .synced:
            return "sync complete ♡"
        case .pendingLocalChanges:
            return "changes waiting on this device"
        case .failed:
            return "sync didn’t finish"
        case .unavailable:
            return "sync unavailable"
        }
    }
}

enum Prompt12DataScope: String, Codable, CaseIterable, Identifiable, Sendable {
    case account
    case savedLibrary
    case guideBuilder
    case settings
    case cycleTracker
    case askCache

    var id: String { rawValue }

    var title: String {
        switch self {
        case .account:
            return "account"
        case .savedLibrary:
            return "saved library"
        case .guideBuilder:
            return "guide builder"
        case .settings:
            return "settings"
        case .cycleTracker:
            return "cycle tracker"
        case .askCache:
            return "ask cache"
        }
    }

    var detail: String {
        switch self {
        case .account:
            return "identity and account-level state"
        case .savedLibrary:
            return "encyclopedias and saved-page metadata"
        case .guideBuilder:
            return "personal guide names, sections, notes, and organization"
        case .settings:
            return "sound, motion, and app preferences"
        case .cycleTracker:
            return "cycle logs, observations, derived estimates, and prediction provenance"
        case .askCache:
            return "temporary local Ask results when supported"
        }
    }
}

struct Prompt12AccountIdentity: Codable, Equatable, Sendable {
    var accountID: UUID
    var provider: String
    var email: String
    var username: String
    var createdAt: Date
    var updatedAt: Date

    init(
        accountID: UUID = UUID(),
        provider: String,
        email: String,
        username: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.accountID = accountID
        self.provider = provider
        self.email = email
        self.username = username
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Prompt12DataExportRecord: Codable, Equatable, Sendable {
    var id: UUID
    var createdAt: Date
    var scopes: [Prompt12DataScope]
    var summary: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        scopes: [Prompt12DataScope],
        summary: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.scopes = scopes
        self.summary = summary
    }
}

enum Prompt12AccountPrivacyError: LocalizedError, Equatable {
    case blankEmail
    case accountServiceUnavailable
    case notSignedIn
    case exportFailed
    case deletionFailed

    var errorDescription: String? {
        switch self {
        case .blankEmail:
            return "enter an email before signing in."
        case .accountServiceUnavailable:
            return "account connection is unavailable. your information remains on this device."
        case .notSignedIn:
            return "there isn’t a signed-in account to change."
        case .exportFailed:
            return "we couldn’t prepare your data right now. nothing was deleted."
        case .deletionFailed:
            return "that deletion did not finish. nothing else was changed."
        }
    }
}
