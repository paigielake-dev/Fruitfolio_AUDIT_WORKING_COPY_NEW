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
    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showDataExport = false
    @State private var usernameDraft = ""
    @State private var usernameMessage: String?

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
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
    }

    private var activeOverlay: Bool {
        showSignOutConfirmation || showDeleteConfirmation || showDataExport
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
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                .padding(.horizontal, 12)
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                .background(DesignTokens.ColorToken.backgroundCream.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))

            Prompt12InfoText("this is your pseudonymous Fruit Basket name. it is shared with the leaderboard and is never derived from your email or legal name.")

            if let usernameMessage {
                Prompt12InfoText(usernameMessage)
                    .multilineTextAlignment(.center)
            }

            WatercolorSecondaryButton(label: "save username") {
                audioManager.play(.buttonSoftPop)
                if let error = usernameStore.setUsername(usernameDraft) {
                    usernameMessage = error
                } else {
                    usernameDraft = usernameStore.username
                    usernameMessage = "saved!"
                }
            }
        }
        .onAppear { usernameDraft = usernameStore.username }
        .onChange(of: usernameStore.username) { _, newValue in
            if usernameDraft != newValue { usernameDraft = newValue }
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

            if let message {
                Prompt12InfoText(message)
                    .multilineTextAlignment(.center)
            }
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
                WatercolorSecondaryButton(label: "sync now") {
                    audioManager.play(.buttonSoftPop)
                    store.syncNow()
                }
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
                    audioManager.play(.buttonSoftPop)
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
                    audioManager.play(.buttonSoftPop)
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
                        audioManager.play(.buttonSoftPop)
                        showSignOutConfirmation = true
                    }
                )

                Divider()
                    .opacity(0.18)

                Prompt12NavigationRow(
                    title: "delete account + data",
                    detail: "requires confirmation before anything changes",
                    assetName: "guide_delete",
                    action: {
                        audioManager.play(.buttonSoftPop)
                        showDeleteConfirmation = true
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var overlayLayer: some View {
        if showSignOutConfirmation {
            Prompt12ConfirmationPopup(
                assetName: "popup_warning",
                title: "before you go…",
                message: store.pendingLocalChanges
                    ? "some changes on this device haven’t finished syncing yet."
                    : "signing out removes the account session. it does not erase local health data.",
                primaryLabel: store.pendingLocalChanges
                    ? "sync now"
                    : "keep on this device + sign out",
                secondaryLabel: "cancel",
                destructiveLabel: nil,
                primaryAction: {
                    if store.pendingLocalChanges {
                        store.syncNow()
                    } else {
                        try? store.signOut(keepLocalData: true)
                    }

                    showSignOutConfirmation = false
                },
                secondaryAction: {
                    showSignOutConfirmation = false
                },
                destructiveAction: nil
            )
        }

        if showDeleteConfirmation {
            Prompt12ConfirmationPopup(
                assetName: "popup_warning",
                title: "delete your account?",
                message: "this removes the Fruitfolio account and applicable associated account data. deleting an account does not cancel or refund the app purchase.",
                primaryLabel: "keep my account",
                secondaryLabel: nil,
                destructiveLabel: "delete account + data",
                primaryAction: {
                    showDeleteConfirmation = false
                },
                secondaryAction: nil,
                destructiveAction: {
                    try? store.deleteAccountAndAssociatedRemoteData()
                    showDeleteConfirmation = false
                }
            )
        }

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

    private func signIn() {
        do {
            try store.signInForDevelopment(email: email)
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
}

