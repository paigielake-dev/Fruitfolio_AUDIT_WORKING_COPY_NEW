import Foundation

/// Deterministic Prompt 04 pacing and complete visible-asset contract.
/// Prompt 04 uses restrained production pacing: every founder-painted book state
/// remains readable without making launch feel cinematic or slow.
enum Prompt04IntroConfiguration {
    static let initialStillness: Duration = .milliseconds(250)

    static let firstLaunchBookArrival: Duration = .milliseconds(650)
    static let blankBookHold: Duration = .milliseconds(250)

    static let logoReveal: Duration = .milliseconds(780)
    static let brandedBookHold: Duration = .milliseconds(300)

    static let slightlyOpenTransition: Duration = .milliseconds(420)
    static let slightlyOpenHold: Duration = .milliseconds(180)

    static let fullyOpenTransition: Duration = .milliseconds(430)
    static let fullyOpenHold: Duration = .milliseconds(220)

    /// Camera move into the right-hand page of the fully open book.
    static let rightPageFocus: Duration = .milliseconds(600)

    /// Resolve from the zoomed book page to the standalone blank paper artwork.
    static let standalonePaperResolve: Duration = .milliseconds(180)

    /// Only after the standalone paper is established do Hub controls appear.
    static let hubReveal: Duration = .milliseconds(200)
    static let completionSettle: Duration = .milliseconds(90)
    static let blueberryHookDelay: Duration = .milliseconds(350)

    // Returning launch keeps the same visual language but skips the first-launch
    // blank-cover/logo-puddle beats and is intentionally much shorter.
    static let returningClosedBookHold: Duration = .milliseconds(180)
    static let returningSlightlyOpenTransition: Duration = .milliseconds(260)
    static let returningFullyOpenTransition: Duration = .milliseconds(300)
    static let returningRightPageFocus: Duration = .milliseconds(450)
    static let returningStandalonePaperResolve: Duration = .milliseconds(150)
    static let returningHubReveal: Duration = .milliseconds(160)

    static let reducedClosedBookCrossfade: Duration = .milliseconds(250)
    static let reducedOpenHubCrossfade: Duration = .milliseconds(300)

    /// Every art asset that can appear during Prompt 04 is preloaded before the
    /// signature animation begins, preventing mid-sequence image flashes.
    static let requiredAssetIDs: [FruitfolioAssetID] = [
        // Branding + all five physical Book files.
        .book_closed_blank,
        .fruitfolio_logo,
        .book_closed_logo,
        .book_slightly_open_logo,
        .book_page_turn,
        .book_open_blank,
        .decor_sparkle_cluster,

        // Hub corner decorations are preloaded with the launch surface so
        // they cannot flash in after the paper/controls resolve.
        .decor_orange_glow,
        .decor_pear,

        // Final standalone founder-painted blank paper surface.
        .ask_answer_paper,

        // Six exact Hub watercolor buttons.
        .button_mint,
        .button_sage,
        .button_peach,
        .button_coral,
        .button_yellow,
        .button_lavender,

        // Six exact Hub symbols.
        .ask_magnifying_glass,
        .hub_bookshelf,
        .guide_folder_add,
        .hub_calendar,
        .hub_basket,
        .hub_question,

        // Three exact Hub utility icons.
        .hub_envelope,
        .hub_settings,
        .hub_account
    ]
}

enum Prompt04LaunchMode: Equatable, Sendable {
    case firstLaunch
    case returningLaunch
    case reducedMotionFirstLaunch
    case reducedMotionReturningLaunch

    var isFirstLaunch: Bool {
        switch self {
        case .firstLaunch, .reducedMotionFirstLaunch: return true
        case .returningLaunch, .reducedMotionReturningLaunch: return false
        }
    }

    var usesReducedMotion: Bool {
        switch self {
        case .reducedMotionFirstLaunch, .reducedMotionReturningLaunch: return true
        case .firstLaunch, .returningLaunch: return false
        }
    }
}

#if DEBUG
enum Prompt04DebugLaunchOverride {
    static func resolve(arguments: [String] = ProcessInfo.processInfo.arguments) -> Prompt04LaunchMode? {
        guard let index = arguments.firstIndex(of: "-FruitfolioIntroMode"),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        switch arguments[index + 1].lowercased() {
        case "first": return .firstLaunch
        case "returning": return .returningLaunch
        case "reduced-first": return .reducedMotionFirstLaunch
        case "reduced-returning": return .reducedMotionReturningLaunch
        default: return nil
        }
    }
}
#endif
