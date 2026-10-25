import Combine
import Foundation

enum FruitfolioAuthenticationState: String, Sendable {
    case signedOut
    case signedIn
}

@MainActor
final class AppState: ObservableObject {
    @Published var hasEnteredMainApp: Bool
    @Published var globalLoading: Bool
    @Published var firstLaunchOnboardingHookReady: Bool
    @Published var authenticationState: FruitfolioAuthenticationState

    @Published var tutorialCompleted: Bool {
        didSet {
            UserDefaults.standard.set(tutorialCompleted, forKey: Self.tutorialCompletedKey)
        }
    }

    @Published var tourWasManuallyReplayed: Bool = false

    private static let tutorialCompletedKey = "fruitfolio.tutorialCompleted"

    var hasAppAccess: Bool {
        FruitfolioPurchasePolicy.normalInstalledUserHasAccess
    }

    var hubAccountLabel: String {
        authenticationState == .signedIn ? "account" : "sign in"
    }

    init(
        hasEnteredMainApp: Bool = false,
        globalLoading: Bool = false,
        firstLaunchOnboardingHookReady: Bool = false,
        tutorialCompleted: Bool? = nil,
        authenticationState: FruitfolioAuthenticationState = .signedOut
    ) {
        self.hasEnteredMainApp = hasEnteredMainApp
        self.globalLoading = globalLoading
        self.firstLaunchOnboardingHookReady = firstLaunchOnboardingHookReady
        self.tutorialCompleted = tutorialCompleted ?? UserDefaults.standard.bool(forKey: Self.tutorialCompletedKey)
        self.authenticationState = authenticationState
    }

    func completeTutorial() {
        tutorialCompleted = true
        tourWasManuallyReplayed = false
    }

    func beginManualTourReplay() {
        tourWasManuallyReplayed = true
    }
}
