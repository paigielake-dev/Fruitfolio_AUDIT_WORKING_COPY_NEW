import Foundation

nonisolated enum Prompt30ContactDestination: String, CaseIterable, Identifiable, Sendable {
    case instagram, tiktok, email, carrd
    var id: String { rawValue }
    var protectedLabelLiterals: [String] {
        switch self {
        case .instagram: ["Instagram", "@fruitsoflife.xo"]
        case .tiktok: ["TikTok", "@fruitsoflife.xo"]
        case .email: ["fruitsoflifexo@gmail.com"]
        case .carrd: ["FruitsofLife.xo", "Carrd"]
        }
    }
    var label: String {
        switch self {
        case .instagram: "Instagram  •  @fruitsoflife.xo"
        case .tiktok: "TikTok  •  @fruitsoflife.xo"
        case .email: "email  •  fruitsoflifexo@gmail.com"
        case .carrd: "FruitsofLife.xo Carrd"
        }
    }
    var url: URL {
        switch self {
        case .instagram: URL(string: "https://www.instagram.com/fruitsoflife.xo")!
        case .tiktok: URL(string: "https://www.tiktok.com/@fruitsoflife.xo?lang=en")!
        case .email: URL(string: "mailto:fruitsoflifexo@gmail.com")!
        case .carrd: URL(string: "https://fruitsoflifexo.carrd.co")!
        }
    }
}

/// View-owned request identity prevents late external-app callbacks from
/// presenting a dialog after leaving Contact or replacing a newer request.
nonisolated struct Prompt30ContactLinkState {
    private(set) var failedDestination: Prompt30ContactDestination?
    private(set) var requestID: UUID?
    private(set) var failureID: UUID?
    private var deferredFailure: (destination: Prompt30ContactDestination, id: UUID)?
    private var isActive = false
    private var requestedDestination: Prompt30ContactDestination?
    private var isVisible = false

    mutating func appear(isActive: Bool = true) {
        isVisible = true
        setActive(isActive)
    }
    mutating func setActive(_ active: Bool) {
        isActive = active
        guard isVisible, active, let deferredFailure else { return }
        failedDestination = deferredFailure.destination
        failureID = deferredFailure.id
        self.deferredFailure = nil
    }
    mutating func disappear() {
        isVisible = false
        isActive = false
        failureID = nil
        deferredFailure = nil
        requestID = nil
        requestedDestination = nil
        failedDestination = nil
    }
    mutating func begin(_ destination: Prompt30ContactDestination) -> UUID? {
        guard isVisible, isActive, failedDestination == nil, deferredFailure == nil else { return nil }
        let id = UUID()
        requestID = id
        requestedDestination = destination
        return id
    }
    mutating func complete(_ id: UUID, accepted: Bool) {
        guard isVisible, id == requestID else { return }
        if !accepted, let destination = requestedDestination {
            deferredFailure = (destination, id)
            setActive(isActive)
        }
        requestID = nil
        requestedDestination = nil
    }
    @discardableResult
    mutating func dismiss(expectedFailureID: UUID? = nil) -> Bool {
        guard isVisible, isActive, let failureID,
              expectedFailureID == nil || expectedFailureID == failureID else { return false }
        failedDestination = nil
        self.failureID = nil
        return true
    }
}
