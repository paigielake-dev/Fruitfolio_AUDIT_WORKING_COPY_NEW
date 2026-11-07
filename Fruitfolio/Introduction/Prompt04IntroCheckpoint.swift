import Foundation

enum Prompt04IntroStage: String, CaseIterable, Sendable {
    case initialStillness
    case blankBookArriving
    case blankBookSettled
    case logoRevealing
    case brandedBookSettled
    case slightlyOpening
    case slightlyOpenSettled
    case fullyOpening
    case fullyOpenSettled
    case rightPageFocusing
    case standalonePaperResolving
    case hubRevealing
    case introComplete
}


/// Restore a safe logical checkpoint; never skip a first-launch logo reveal
/// which had not begun, and never insert that reveal into a returning launch.
enum Prompt04IntroCheckpoint: Equatable, Sendable {
    case blankBook, brandedBook, slightlyOpenBook, fullyOpenBook, hubPaper, complete

    static func resolve(stage: Prompt04IntroStage, firstLaunch: Bool) -> Self {
        switch stage {
        case .initialStillness, .blankBookArriving, .blankBookSettled:
            return firstLaunch ? .blankBook : .brandedBook
        case .logoRevealing, .brandedBookSettled: return .brandedBook
        case .slightlyOpening, .slightlyOpenSettled: return .slightlyOpenBook
        case .fullyOpening, .fullyOpenSettled, .rightPageFocusing: return .fullyOpenBook
        case .standalonePaperResolving, .hubRevealing: return .hubPaper
        case .introComplete: return .complete
        }
    }
}
