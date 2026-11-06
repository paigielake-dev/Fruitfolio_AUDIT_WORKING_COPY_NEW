import SwiftUI

struct Prompt12AccountView: View {
    @ObservedObject var store: Prompt12AccountPrivacyStore

    let onBack: () -> Void
    let onShowPrivacy: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @ObservedObject private var usernameStore = FruitfolioUsernameStore.shared

    @State private var email = ""
    @State private var message: String?
    private enum AccountControl: Hashable { case signOut, deleteAccount, sync, message }
    private enum AccountAction {
        case signOut(Prompt12AccountActionSnapshot)
        case sync(Prompt12AccountActionSnapshot)
        case delete(Prompt12AccountActionSnapshot)
    }
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var popupScope = UUID()
    @State private var pendingAccountAction: AccountAction?
    @State private var returnAccountFocus: AccountControl?
    @State private var viewIsVisible = false
    @State private var messageFocusRequest = UUID()
    @AccessibilityFocusState private var accountFocus: AccountControl?
    @State private var showDataExport = false
    @State private var usernameDraft = ""
    @State private var usernameNonIdentifying = false
    @State private var usernameMessage: String?

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
                            onBack: onBack
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
                            .task(id: messageFocusRequest) {
                                await Task.yield()
                                guard !Task.isCancelled, viewIsVisible, popupCoordinator.currentPopup == nil else { return }
                                accountFocus = .message
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 42)
            }
            .scrollIndicators(.hidden)
            .fruitfolioModalBlur(
                active: activeOverlay,
                reduceMotion: motionPreferences.reduceMotionActive
            )

            if activeOverlay {
                DesignTokens.ColorToken.backgroundCream
                    .opacity(FruitfolioModalBlurSpec.dimOpacity)
                    .ignoresSafeArea()
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
            popupOwner?.cancel()
            pendingAccountAction = nil
            returnAccountFocus = nil
        }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            popupOwner?.observeDismissal()
            guard viewIsVisible, popupOwner?.requestID == nil, popupCoordinator.currentPopup == nil else { return }
            if let action = pendingAccountAction {
                pendingAccountAction = nil
                returnAccountFocus = nil
                performAccountAction(action)
            } else if let control = returnAccountFocus {
                returnAccountFocus = nil
                accountFocus = control
            }
        }
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
                    Text(store.ownershipDisplayText)
                        .font(.custom("Chalkboard SE", size: 14))
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
        Prompt12PaperCard {
            Text("fruit basket username")
                .font(.custom("Chalkboard SE", size: 16, relativeTo: .headline))
                .fontWeight(.bold)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)

            TextField("public username", text: $usernameDraft)
                .accessibilityIdentifier("account.publicUsername")
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                .padding(.horizontal, 12)
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                .background(DesignTokens.ColorToken.backgroundCream.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))

            Prompt12InfoText("this is your pseudonymous Fruit Basket name. Account and Fruit Basket use the same locally saved name. public registration and global uniqueness are unavailable until the secure service is configured.")

            Toggle("this is not my real or legal name and contains no identifying details", isOn: $usernameNonIdentifying)
                .font(.caption)

            if let usernameMessage {
                Prompt12InfoText(usernameMessage)
                    .multilineTextAlignment(.center)
            }

            WatercolorSecondaryButton(label: "save username") {
                if let error = usernameStore.setUsername(usernameDraft, confirmedNonIdentifying: usernameNonIdentifying, identifyingText: [email, store.account?.email ?? ""]) {
                    usernameMessage = error
                } else {
                    usernameDraft = usernameStore.username
                    usernameMessage = "saved!"
                }
            }
        }
        .onAppear { usernameDraft = usernameStore.username; usernameNonIdentifying = usernameStore.confirmedNonIdentifying }
        .onChange(of: usernameDraft) { _, newValue in
            usernameNonIdentifying = newValue == usernameStore.username && usernameStore.confirmedNonIdentifying
        }
        .onChange(of: usernameStore.username) { oldValue, newValue in
            if usernameDraft == oldValue || usernameDraft == newValue {
                usernameDraft = newValue
                usernameNonIdentifying = usernameStore.confirmedNonIdentifying
            } else {
                usernameNonIdentifying = false
                usernameMessage = "the saved username changed in Fruit Basket. your unsaved draft is still here; confirm it again before saving."
            }
        }
    }

    private var signedOutCard: some View {
        Prompt12PaperCard {
            Text("sign in")
                .font(.custom("Chalkboard SE", size: 16))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

            Prompt12InfoText(
                "sign in to keep supported Fruitfolio data connected to you across devices. local features can still use local storage when available."
            )

            TextField("email", text: $email)
                .font(.custom("Chalkboard SE", size: 12.5))
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

    private var signedInCard: some View {
        Prompt12PaperCard {
            Text(store.accountDisplayName)
                .font(.custom("Chalkboard SE", size: 17))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

            if let account = store.account {
                Prompt12InfoText(
                    "signed in with \(account.provider) / \(account.email)"
                )
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
                    onShowPrivacy()
                }
            )

            Divider()
                .opacity(0.18)

            Prompt12NavigationRow(
                title: "export my data",
                detail: "prepare supported account and local data",
                assetName: "ask_source_pages",
                action: {
                    showDataExport = true
                }
            )

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
                    showDataExport = false
                }
            )
        }
    }

    private func showMessage(_ text: String) {
        message = text
        messageFocusRequest = UUID()
    }

    private func performAccountAction(_ action: AccountAction) {
        guard viewIsVisible else { return }
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
            }
        } catch { showMessage(error.localizedDescription) }
    }

    private func requestSignOut() {
        guard viewIsVisible, let owner = popupOwner else { return }
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
                    guard viewIsVisible else { return }
                    _ = owner.consumeAction(for: id)
                }, secondaryAction: .init(label: "keep on this device + sign out") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
                    pendingAccountAction = .signOut(expected)
                }, tertiaryAction: expected.pendingLocalChanges ? .init(label: "try cloud sync") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
                    pendingAccountAction = .sync(expected)
                } : nil,
                dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "account-sign-out", deduplicationKey: "account-sign-out-" + popupScope.uuidString,
                surface: .tapedWhite)
        }
    }

    private func requestAccountDeletion() {
        guard viewIsVisible, let owner = popupOwner else { return }
        if let id = owner.requestID, popupCoordinator.containsRequest(id: id) { return }
        let expected = store.accountActionSnapshot
        returnAccountFocus = .deleteAccount
        accountFocus = nil
        owner.present { id in
            FruitPopupRequest(id: id, character: .peach,
                message: "**request account deletion?**\n\naccount deletion needs confirmation from the account service. this action does not erase local health files or cancel or refund the app purchase. any failure will be shown before success is claimed.",
                primaryAction: .init(label: "keep my account") {
                    guard viewIsVisible else { return }
                    _ = owner.consumeAction(for: id)
                }, secondaryAction: .init(label: "request account deletion") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
                    pendingAccountAction = .delete(expected)
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "account-deletion", deduplicationKey: "account-deletion-" + popupScope.uuidString,
                surface: .tapedWhite)
        }
    }

    private func signIn() {
        do {
            try store.requestSignIn(email: email)
            message = nil
        } catch {
            showMessage(error.localizedDescription)
        }
    }
}

