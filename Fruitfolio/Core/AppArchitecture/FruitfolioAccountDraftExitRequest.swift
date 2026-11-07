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
        let spans = messageSpans(hasUsernameDraft: hasUsernameDraft,
            hasEmailDraft: hasEmailDraft, canSaveUsername: canSaveUsername)
        let message = FruitfolioSemanticMarkup.markdown(
            FruitfolioSemanticPolicy.normalized(spans, serious: true))
        return FruitPopupRequest(id: id, character: .peach, message: message,
            primaryAction: .init(label: "keep editing", handler: onKeep),
            secondaryAction: .init(label: offersSave ? "save username + leave" : "discard drafts + leave",
                handler: offersSave ? onSaveUsername : onDiscard),
            tertiaryAction: offersSave ? .init(label: "discard drafts + leave", handler: onDiscard) : nil,
            dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
            source: "account-draft-exit", deduplicationKey: "account-draft-exit-" + scope.uuidString,
            surface: .tapedWhite)
    }
    /// Explicit roles for these complete authored contexts. Entered drafts are
    /// never supplied to this formatter or included in popup metadata.
    static func messageSpans(hasUsernameDraft: Bool, hasEmailDraft: Bool,
                             canSaveUsername: Bool) -> [FruitfolioSemanticSpan] {
        if hasUsernameDraft && !canSaveUsername {
            return [.init(text: "unsaved account edits", emphasis: .anchorBold),
                .init(text: "\n\nthe "),
                .init(text: "saved username record is protected", emphasis: .symptomOrPracticalUnderline),
                .init(text: ". keep the drafts to review it, or discard only these unsaved edits and leave. your saved information stays in place.")]
        } else if hasUsernameDraft && hasEmailDraft {
            return [.init(text: "unsaved account edits", emphasis: .anchorBold),
                .init(text: "\n\nyour username edit and sign-in email are not saved. saving the username only saves that name on this device; it "),
                .init(text: "does not submit or save the email", emphasis: .symptomOrPracticalUnderline),
                .init(text: ". leaving will discard the email draft.")]
        } else if hasUsernameDraft {
            return [.init(text: "unsaved username", emphasis: .anchorBold),
                .init(text: "\n\nyour username edit has not been saved. save it "),
                .init(text: "on this device", emphasis: .symptomOrPracticalUnderline),
                .init(text: ", discard only this edit, or keep editing. other saved information is separate.")]
        } else {
            return [.init(text: "unsaved sign-in email", emphasis: .anchorBold),
                .init(text: "\n\nyou have not submitted this email. keep editing, or discard this draft and leave. leaving "),
                .init(text: "does not sign in or change your account", emphasis: .symptomOrPracticalUnderline),
                .init(text: ".")]
        }
    }

}
