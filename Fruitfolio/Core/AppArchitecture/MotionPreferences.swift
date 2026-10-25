import Combine
import Foundation
import SwiftUI

/// Central authority for whether Fruitfolio should reduce motion.
@MainActor
final class MotionPreferences: ObservableObject {
    @Published private(set) var systemReduceMotion: Bool = false
    @Published private(set) var appReduceMotionOverride: Bool = false

    var reduceMotionActive: Bool {
        systemReduceMotion || appReduceMotionOverride
    }

    var allowMicroMotion: Bool { !reduceMotionActive }
    var allowComponentMotion: Bool { !reduceMotionActive }
    var allowStorybookMotion: Bool { !reduceMotionActive }
    var allowCelebrationMotion: Bool { !reduceMotionActive }

    func update(systemReduceMotion: Bool, appOverride: Bool) {
        self.systemReduceMotion = systemReduceMotion
        self.appReduceMotionOverride = appOverride
    }

    /// Prompt 02 owns the concrete animation vocabulary and reduced-motion substitutions.
    func resolvedAnimation(for category: FruitfolioMotionCategory) -> Animation? {
        FruitfolioMotion.animation(category, reduceMotion: reduceMotionActive)
    }
}
