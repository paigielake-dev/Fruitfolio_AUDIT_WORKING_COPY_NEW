import Combine
import Foundation

/// Prompt 04 launch persistence. Signature Intro completion is intentionally
/// independent from Prompt 03's onboarding completion preference.
@MainActor
final class IntroLaunchStore: ObservableObject {
    private enum Key {
        static let hasCompletedSignatureIntro = "fruitfolio.launch.hasCompletedSignatureIntro"
    }

    private let defaults: UserDefaults

    @Published var hasCompletedSignatureIntro: Bool {
        didSet {
            defaults.set(hasCompletedSignatureIntro, forKey: Key.hasCompletedSignatureIntro)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasCompletedSignatureIntro = defaults.bool(forKey: Key.hasCompletedSignatureIntro)
    }

    func markSignatureIntroComplete() {
        hasCompletedSignatureIntro = true
    }

    #if DEBUG
    func resetSignatureIntroForDebug() {
        hasCompletedSignatureIntro = false
    }
    #endif
}
