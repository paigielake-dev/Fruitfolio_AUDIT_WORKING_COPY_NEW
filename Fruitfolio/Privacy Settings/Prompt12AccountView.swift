import SwiftUI
import UIKit

@MainActor
struct Prompt12AccountView: View {
    @ObservedObject var store: Prompt12AccountPrivacyStore

    let onBack: () -> Void
    let onShowPrivacy: () -> Void
    private let onShowDataExport: (() -> Void)?

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var usernameLabel = FruitfolioControlTranslationState()
    @StateObject private var emailLabel = FruitfolioControlTranslationState()
    private var usernameLabelKey: FruitfolioControlTranslationState.Key {
        .init(source: "public username", language: settings.language)
    }
    private var emailLabelKey: FruitfolioControlTranslationState.Key {
        .init(source: "email", language: settings.language)
    }
    @ObservedObject private var usernameStore: FruitfolioUsernameStore

    @State private var email = ""
    @State private var message: String?
    private enum AccountControl: Hashable { case signOut, deleteAccount, sync, message, dataExport, usernameInput, emailInput, usernameError }
    private enum AccountExit { case back, privacy, dataExport }
    private enum AccountAction {
        case signOut(Prompt12AccountActionSnapshot)
        case sync(Prompt12AccountActionSnapshot)
        case delete(Prompt12AccountActionSnapshot)
        case leaveDiscardingDrafts(AccountExit)
        case saveUsernameAndLeave(FruitfolioUsernameSaveIntent, AccountExit)
    }
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var popupScope = UUID()
    @State private var pendingAccountAction: AccountAction?
    @State private var returnAccountFocus: AccountControl?
    @State private var viewIsVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var focusTask: Task<Void, Never>?
    @AccessibilityFocusState private var accountFocus: AccountControl?
    @State private var showDataExport = false
    @State private var usernameDraft = ""
    @State private var usernameBaseline: FruitfolioUsernamePersistence.Snapshot?
    @State private var usernameEditorHasLoaded = false
    @State private var usernameNonIdentifying = false
    @State private var usernameMessage: String?

    init(store: Prompt12AccountPrivacyStore, onBack: @escaping () -> Void,
         onShowPrivacy: @escaping () -> Void, usernameStore: FruitfolioUsernameStore = .shared,
         onShowDataExport: (() -> Void)? = nil) {
        _store = ObservedObject(wrappedValue: store)
        _usernameStore = ObservedObject(wrappedValue: usernameStore)
        self.onBack = onBack
        self.onShowPrivacy = onShowPrivacy
        self.onShowDataExport = onShowDataExport
    }

    private var canUseAccount: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
    }
    private var canEditAccount: Bool {
        canUseAccount && !showDataExport && popupCoordinator.currentPopup == nil
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Prompt12SavedRecordNotice(store: store)
                    ZStack(alignment: .topTrailing) {
                        Prompt12RouteHeader(
                            title: "your account",
                            subtitle: "your little corner of Fruitfolio ♡",
                            assetName: "hub_account",
                            onBack: { requestLeavingAccount() }
                        )

                        HStack(spacing: -7) {
                            FruitfolioImage(id: .fruitbasket_apple)
                                .frame(width: 46, height: 46)
                            FruitfolioImage(id: .fruitbasket_peach)
                                .frame(width: 46, height: 46)
                            FruitfolioImage(id: .fruitbasket_star)
                                .frame(width: 22, height: 22)
                                .offset(y: -13)
                        }
                        .padding(.top, 2)
                        .padding(.trailing, 2)
                         .allowsHitTesting(false)
                        .accessibilityHidden(true)

                        FruitfolioImage(id: .decor_sparkles_2)
                            .frame(width: 88, height: 88)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .offset(x: 44, y: -12)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }

                    ownershipCard
                    usernameCard

                    if store.isSignedIn {
                        signedInCard
                    } else {
                        signedOutCard
                    }

                    accountActions
                    if let message {
                        FruitfolioTranslatedText(source: message,
                            font: .custom("Chalkboard SE", size: 14, relativeTo: .body),
                            color: DesignTokens.ColorToken.primaryBurgundy, serious: true)
                            .accessibilityFocused($accountFocus, equals: .message)
                            .accessibilityIdentifier("account.actionMessage")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 42)
            }
            .scrollIndicators(.hidden)
            .disabled(!canEditAccount)
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("account.scroll")
            .fruitfolioModalBlur(
                active: activeOverlay,
                reduceMotion: motionPreferences.reduceMotionActive
            )

            if activeOverlay {
                FruitfolioModalBackdrop()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .zIndex(90)
            }

            overlayLayer
                .zIndex(100)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewIsVisible = true
            if popupOwner == nil { popupOwner = FruitfolioOwnedPopupSession(coordinator: popupCoordinator) }
        }
        .onDisappear {
            viewIsVisible = false
            focusTask?.cancel(); focusTask = nil
            popupOwner?.cancel()
            pendingAccountAction = nil
            returnAccountFocus = nil
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                focusTask?.cancel(); focusTask = nil
                accountFocus = nil
                if pendingAccountAction != nil {
                    pendingAccountAction = nil
                    showMessage("that account action was interrupted. review and confirm it again.")
                }
            } else { finishAccountPopupDismissal() }
        }
        .onChange(of: showDataExport) { _, presented in
            if presented { focusTask?.cancel(); focusTask = nil; accountFocus = nil }
            else { requestAccountFocus(.dataExport) }
        }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, id in
            popupOwner?.observeDismissal()
            if id != nil { focusTask?.cancel(); focusTask = nil; accountFocus = nil }
            else { finishAccountPopupDismissal() }
        }
    }

    private func finishAccountPopupDismissal() {
        guard canEditAccount, popupOwner?.requestID == nil else { return }
        if let action = pendingAccountAction {
            pendingAccountAction = nil
            returnAccountFocus = nil
            performAccountAction(action)
        } else { restoreAccountFocus() }
    }

    private func requestAccountFocus(_ control: AccountControl) {
        returnAccountFocus = control
        restoreAccountFocus()
    }

    private func restoreAccountFocus() {
        guard canEditAccount, let control = returnAccountFocus else { return }
        focusTask?.cancel()
        focusTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, canEditAccount, returnAccountFocus == control else { return }
            accountFocus = control
            returnAccountFocus = nil
            focusTask = nil
        }
    }

    private func admittedBinding<Value>(_ binding: Binding<Value>) -> Binding<Value> {
        Binding(get: { binding.wrappedValue }, set: { value in
            guard canEditAccount else { return }
            binding.wrappedValue = value
        })
    }

    private var activeOverlay: Bool {
        showDataExport
    }

    private var ownershipCard: some View {
        Prompt12PaperCard {
            HStack(spacing: 10) {
                Image("popup_info")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    FruitfolioTranslatedText(source: store.ownershipDisplayText,
                        protectedLiterals: ["Fruitfolio"],
                        font: .custom("Chalkboard SE", size: 14, relativeTo: .headline))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )

                    Prompt12InfoText(store.ownershipState.displayDetail)
                }
            }
        }
    }


    private var usernameCard: some View {
        let input = usernameLabel.presentation(for: usernameLabelKey)
        return Prompt12PaperCard {
            FruitfolioTranslatedText(source: "fruit basket username",
                font: .custom("Chalkboard SE", size: 16, relativeTo: .headline))
                .fontWeight(.bold)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)

            TextField("", text: admittedBinding($usernameDraft),
                prompt: Text(FruitfolioSemanticDocument.plainText(from: input.text)))
                .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: input.text)))
                .modifier(FruitfolioFixedAccessibilityHint(source: Prompt28LeaderboardUsernamePolicy.inputInstructions,
                    supplementalDetail: input.status.accessibilityDetail(original: usernameLabelKey.source,
                        localized: { settings.localized($0) })))
                .task(id: FruitfolioControlTranslationState.TaskKey(key: usernameLabelKey,
                    inferenceAllowed: settings.translationInferenceAllowed)) {
                    await usernameLabel.resolve(usernameLabelKey, inferenceAllowed: settings.translationInferenceAllowed)
                }
                .accessibilityFocused($accountFocus, equals: .usernameInput)
                .accessibilityIdentifier("account.publicUsername")
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                .padding(.horizontal, 12)
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                .background(DesignTokens.ColorToken.backgroundCream.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))

            inputTranslationCaption(input.status)

            Prompt12InfoText("this is your pseudonymous Fruit Basket name. Account and Fruit Basket use the same locally saved name. public registration and global uniqueness are unavailable until the secure service is configured.")

            WatercolorToggle(label: "this is not my real or legal name and contains no identifying details",
                isOn: admittedBinding($usernameNonIdentifying))
                .accessibilityIdentifier("account.usernameConfirmation")

            if let issue = usernameStore.persistenceMessage {
                Prompt12InfoText(issue)
                WatercolorSecondaryButton(label: "reload saved username") {
                    guard canEditAccount else { return }
                    usernameStore.reloadSavedUsername()
                }
                    .accessibilityIdentifier("account.reloadUsername")
            }
            if let usernameMessage {
                Prompt12InfoText(usernameMessage)
                    .multilineTextAlignment(.center)
                    .accessibilityFocused($accountFocus, equals: .usernameError)
                    .accessibilityIdentifier("account.usernameError")
            }

            WatercolorSecondaryButton(label: "save username") {
                guard canEditAccount else { return }
                if let error = usernameStore.setUsername(usernameDraft, confirmedNonIdentifying: usernameNonIdentifying,
                    identifyingText: [email, store.account?.email ?? ""], expecting: usernameBaseline) {
                    usernameNonIdentifying = false
                    usernameMessage = error
                } else {
                    usernameDraft = usernameStore.username
                    usernameBaseline = usernameStore.snapshot
                    usernameMessage = "saved!"
                }
            }
            .disabled(!usernameStore.canPersistUsername || usernameBaseline == nil)
            .accessibilityIdentifier("account.saveUsername")
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioAccountActionQA") {
                Text("saved username: \(usernameStore.debugStoredUsername.username)")
                    .accessibilityIdentifier("account.qa.savedUsername")
            }
            #endif
        }
        .onAppear {
            let current = usernameStore.snapshot
            if !usernameEditorHasLoaded || usernameBaseline.map({ usernameDraft == $0.username }) == true {
                usernameEditorHasLoaded = true
                usernameDraft = current.username
                usernameNonIdentifying = current.confirmedNonIdentifying
                usernameBaseline = current
            } else if usernameBaseline != current {
                usernameNonIdentifying = false
                usernameMessage = "the saved username changed. your unsaved draft is still here; confirm it again before saving."
            }
        }
        .onChange(of: usernameNonIdentifying) { _, confirmed in
            // An explicit re-confirmation authorizes the currently reviewed name.
            if confirmed { usernameBaseline = usernameStore.snapshot }
        }
        .onChange(of: usernameDraft) { _, newValue in
            usernameNonIdentifying = newValue == usernameStore.username && usernameStore.confirmedNonIdentifying
        }
        .onChange(of: usernameStore.username) { oldValue, newValue in
            if usernameDraft == oldValue || usernameDraft == newValue {
                usernameDraft = newValue
                usernameNonIdentifying = usernameStore.confirmedNonIdentifying
                usernameBaseline = usernameStore.snapshot
            } else {
                usernameNonIdentifying = false
                usernameMessage = "the saved username changed in Fruit Basket. your unsaved draft is still here; confirm it again before saving."
            }
        }
    }

    private var signedOutCard: some View {
        let input = emailLabel.presentation(for: emailLabelKey)
        return Prompt12PaperCard {
            FruitfolioTranslatedText(source: "sign in",
                font: .custom("Chalkboard SE", size: 16, relativeTo: .headline))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

            Prompt12InfoText(
                "sign in to keep supported Fruitfolio data connected to you across devices. local features can still use local storage when available."
            )

            TextField("", text: admittedBinding($email),
                prompt: Text(FruitfolioSemanticDocument.plainText(from: input.text)))
                .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: input.text)))
                .accessibilityHint(Text(input.status.accessibilityDetail(
                    original: emailLabelKey.source, localized: { settings.localized($0) })))
                .accessibilityFocused($accountFocus, equals: .emailInput)
                .accessibilityIdentifier("account.email")
                .task(id: FruitfolioControlTranslationState.TaskKey(key: emailLabelKey,
                    inferenceAllowed: settings.translationInferenceAllowed)) {
                    await emailLabel.resolve(emailLabelKey, inferenceAllowed: settings.translationInferenceAllowed)
                }
                .font(.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .textFieldStyle(.plain)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .tint(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .padding(.horizontal, 12)
                .frame(minHeight: 46)
                .background(
                    DesignTokens.ColorToken.backgroundCream.opacity(0.88),
                    in: RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )

            inputTranslationCaption(input.status)

            FruitfolioControlPillButton(
                label: "sign in"
            ) {
                signIn()
            }
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )

        }
    }

    @ViewBuilder
    private func inputTranslationCaption(_ status: FruitfolioControlTranslationState.Presentation.Status) -> some View {
        if let key = status.captionKey {
            Text(LocalizedStringKey(key))
                .font(.custom("Chalkboard SE", size: 11, relativeTo: .caption))
                .foregroundStyle(DesignTokens.ColorToken.secondaryBurgundy)
                .accessibilityHidden(true) // The actual field carries this status in its hint.
        }
    }

    private var signedInCard: some View {
        Prompt12PaperCard {
            Group {
                if usernameStore.username.isEmpty {
                    FruitfolioFixedText(source: "local Fruitfolio", protectedLiterals: ["Fruitfolio"], serious: true)
                } else { Text(verbatim: usernameStore.username) }
            }
                .accessibilityIdentifier("account.sharedUsername")
                .font(.custom("Chalkboard SE", size: 17, relativeTo: .headline))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

            if let account = store.account {
                let status = Prompt12AccountStatusText(identity: account)
                Prompt12InfoText(status.source, protectedLiterals: status.protectedLiterals)
            }

            Prompt12StatusPill(
                text: store.syncState.displayText,
                assetName: store.syncState == .synced
                    ? "control_check"
                    : "popup_info"
            )

            if store.pendingLocalChanges {
                WatercolorSecondaryButton(label: "try cloud sync") {
                    performAccountAction(.sync(store.accountActionSnapshot))
                }
                .accessibilityFocused($accountFocus, equals: .sync)
                .accessibilityIdentifier("account.sync")
            }
        }
    }

    private var accountActions: some View {
        Prompt12PaperCard {
            Prompt12NavigationRow(
                title: "privacy",
                detail: "how Fruitfolio handles your information",
                assetName: "popup_info",
                action: {
                    guard canEditAccount else { return }
                    requestLeavingAccount(to: .privacy)
                }
            )
            .accessibilityIdentifier("account.privacy")

            Divider()
                .opacity(0.18)

            Prompt12NavigationRow(
                title: "export my data",
                detail: "prepare supported account and local data",
                assetName: "ask_source_pages",
                action: {
                    guard canEditAccount else { return }
                    if onShowDataExport != nil { requestLeavingAccount(to: .dataExport) }
                    else { showDataExport = true }
                }
            )
            .accessibilityFocused($accountFocus, equals: .dataExport)
            .accessibilityIdentifier("account.dataExport")

            if store.isSignedIn {
                Divider()
                    .opacity(0.18)

                Prompt12NavigationRow(
                    title: "sign out",
                    detail: "keep local data separate from account access",
                    assetName: "control_undo",
                    action: {
                        requestSignOut()
                    }
                )
                .accessibilityFocused($accountFocus, equals: .signOut)
                .accessibilityIdentifier("account.signOut")

                Divider()
                    .opacity(0.18)

                Prompt12NavigationRow(
                    title: "delete account",
                    detail: "review account deletion; local health information is separate",
                    assetName: "guide_delete",
                    action: {
                        requestAccountDeletion()
                    }
                )
                .accessibilityFocused($accountFocus, equals: .deleteAccount)
                .accessibilityIdentifier("account.deleteAccount")
            }
        }
    }

    @ViewBuilder
    private var overlayLayer: some View {
        if showDataExport {
            Prompt12DataManagementView(
                store: store,
                mode: .popup,
                onBack: {
                    guard canUseAccount, showDataExport, popupCoordinator.currentPopup == nil else { return }
                    showDataExport = false
                }
            )
        }
    }

    private func showMessage(_ text: String) {
        message = text
        requestAccountFocus(.message)
    }

    private func performAccountAction(_ action: AccountAction) {
        guard canEditAccount else { return }
        do {
            switch action {
            case .signOut(let expected):
                try store.signOut(keepLocalData: true, expecting: expected)
                showMessage(store.pendingLocalChanges
                    ? "signed out. local information and pending changes remain on this device."
                    : "signed out. local information remains on this device.")
            case .sync(let expected):
                try store.attemptSyncNow(expecting: expected)
            case .delete(let expected):
                try store.deleteAccountAndAssociatedRemoteData(expecting: expected)
            case .leaveDiscardingDrafts(let destination):
                discardLocalAccountDraftsAndLeave(to: destination)
            case .saveUsernameAndLeave(let intent, let destination):
                if let error = intent.commit(to: usernameStore) {
                    usernameMessage = error
                    usernameNonIdentifying = false
                    requestAccountFocus(.usernameError)
                } else {
                    usernameDraft = usernameStore.username
                    usernameBaseline = usernameStore.snapshot
                    usernameNonIdentifying = usernameStore.confirmedNonIdentifying
                    usernameMessage = "saved on this device only."
                    email = "" // Explicitly disclosed as an unsubmitted draft, never an account update.
                    completeAccountExit(destination)
                }
            }
        } catch { showMessage(error.localizedDescription) }
    }

    private func requestLeavingAccount(to destination: AccountExit = .back) {
        guard canEditAccount else { return }
        let hasUsernameDraft = usernameEditorHasLoaded &&
            usernameBaseline.map({ usernameDraft != $0.username }) == true
        let hasEmailDraft = !email.isEmpty
        guard hasUsernameDraft || hasEmailDraft else { completeAccountExit(destination); return }
        guard let owner = popupOwner else { return }
        if let id = owner.requestID, popupCoordinator.containsRequest(id: id) { return }
        let intent = usernameBaseline.map {
            FruitfolioUsernameSaveIntent(raw: usernameDraft, confirmedNonIdentifying: usernameNonIdentifying,
                expected: $0, identifyingText: [email, store.account?.email ?? ""])
        }
        returnAccountFocus = hasUsernameDraft ? .usernameInput : .emailInput
        accountFocus = nil
        owner.present { id in
            FruitfolioAccountDraftExitRequest.make(id: id, scope: popupScope,
                hasUsernameDraft: hasUsernameDraft, hasEmailDraft: hasEmailDraft,
                canSaveUsername: usernameStore.canPersistUsername && intent != nil,
                onKeep: {
                    guard canUseAccount else { return }
                    _ = owner.consumeAction(for: id)
                }, onSaveUsername: {
                    guard canUseAccount, let intent, owner.consumeAction(for: id) else { return }
                    pendingAccountAction = .saveUsernameAndLeave(intent, destination)
                }, onDiscard: {
                    guard canUseAccount, owner.consumeAction(for: id) else { return }
                    pendingAccountAction = .leaveDiscardingDrafts(destination)
                })
        }
    }

    private func discardLocalAccountDraftsAndLeave(to destination: AccountExit) {
        usernameDraft = usernameStore.username
        usernameNonIdentifying = usernameStore.confirmedNonIdentifying
        usernameBaseline = usernameStore.snapshot
        usernameMessage = nil
        email = ""
        completeAccountExit(destination)
    }

    private func completeAccountExit(_ destination: AccountExit) {
        guard canEditAccount else { return }
        switch destination {
        case .back: onBack()
        case .privacy: onShowPrivacy()
        case .dataExport: onShowDataExport?()
        }
    }

    private func requestSignOut() {
        guard canEditAccount, let owner = popupOwner else { return }
        if let id = owner.requestID, popupCoordinator.containsRequest(id: id) { return }
        let expected = store.accountActionSnapshot
        returnAccountFocus = .signOut
        accountFocus = nil
        owner.present { id in
            FruitPopupRequest(id: id, character: .peach,
                message: expected.pendingLocalChanges
                    ? "**before you go…**\n\nsome local changes have not been synced. signing out can keep them on this device. cloud synchronization requires a configured account service."
                    : "**before you go…**\n\nsigning out removes the account session and keeps local health information on this device.",
                primaryAction: .init(label: "cancel") {
                    guard canUseAccount else { return }
                    _ = owner.consumeAction(for: id)
                }, secondaryAction: .init(label: "keep on this device + sign out") {
                    guard canUseAccount, owner.consumeAction(for: id) else { return }
                    pendingAccountAction = .signOut(expected)
                }, tertiaryAction: expected.pendingLocalChanges ? .init(label: "try cloud sync") {
                    guard canUseAccount, owner.consumeAction(for: id) else { return }
                    pendingAccountAction = .sync(expected)
                } : nil,
                dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "account-sign-out", deduplicationKey: "account-sign-out-" + popupScope.uuidString,
                surface: .tapedWhite)
        }
    }

    private func requestAccountDeletion() {
        guard canEditAccount, let owner = popupOwner else { return }
        if let id = owner.requestID, popupCoordinator.containsRequest(id: id) { return }
        let expected = store.accountActionSnapshot
        returnAccountFocus = .deleteAccount
        accountFocus = nil
        owner.present { id in
            FruitPopupRequest(id: id, character: .peach,
                message: "**request account deletion?**\n\naccount deletion needs confirmation from the account service. this action does not erase local health information or cancel or refund the app purchase. your account stays in place unless deletion is confirmed.",
                primaryAction: .init(label: "keep my account") {
                    guard canUseAccount else { return }
                    _ = owner.consumeAction(for: id)
                }, secondaryAction: .init(label: "request account deletion") {
                    guard canUseAccount, owner.consumeAction(for: id) else { return }
                    pendingAccountAction = .delete(expected)
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "account-deletion", deduplicationKey: "account-deletion-" + popupScope.uuidString,
                surface: .tapedWhite)
        }
    }

    private func signIn() {
        guard canEditAccount else { return }
        do {
            try store.requestSignIn(email: email)
            message = nil
        } catch {
            showMessage(error.localizedDescription)
        }
    }
}

