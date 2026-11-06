import Foundation

/// Pure shared-paper request for unsaved local form state. No entered value or
/// identity is included in the message or routing metadata.
@MainActor
enum FruitfolioAccountDraftExitRequest {
    static func make(id: UUID, scope: UUID, hasUsernameDraft: Bool, hasEmailDraft: Bool,
                     canSaveUsername: Bool, onKeep: @escaping @MainActor () -> Void,
                     onSaveUsername: @escaping @MainActor () -> Void,
                     onDiscard: @escaping @MainActor () -> Void) -> FruitPopupRequest {
        let offersSave = hasUsernameDraft && canSaveUsername
        let message: String
        if hasUsernameDraft && !canSaveUsername {
            message = "**unsaved account edits**\n\nthe saved username record is protected. keep the drafts to review it, or discard only these unsaved edits and leave. your saved information stays in place."
        } else if hasUsernameDraft && hasEmailDraft {
            message = "**unsaved account edits**\n\nyour username edit and sign-in email are not saved. saving the username only saves that name on this device; it does not submit or save the email. leaving will discard the email draft."
        } else if hasUsernameDraft {
            message = "**unsaved username**\n\nyour username edit has not been saved. save it on this device, discard only this edit, or keep editing. other saved information is separate."
        } else {
            message = "**unsaved sign-in email**\n\nyou have not submitted this email. keep editing, or discard this draft and leave. leaving does not sign in or change your account."
        }
        return FruitPopupRequest(id: id, character: .peach, message: message,
            primaryAction: .init(label: "keep editing", handler: onKeep),
            secondaryAction: .init(label: offersSave ? "save username + leave" : "discard drafts + leave",
                handler: offersSave ? onSaveUsername : onDiscard),
            tertiaryAction: offersSave ? .init(label: "discard drafts + leave", handler: onDiscard) : nil,
            dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
            source: "account-draft-exit", deduplicationKey: "account-draft-exit-" + scope.uuidString,
            surface: .tapedWhite)
    }
}
