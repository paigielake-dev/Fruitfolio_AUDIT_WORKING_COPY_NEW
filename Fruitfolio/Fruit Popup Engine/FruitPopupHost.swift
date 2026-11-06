import SwiftUI

private struct FruitfolioPopupHostPresentKey: EnvironmentKey {
    static let defaultValue = false
}
fileprivate extension EnvironmentValues {
    var fruitfolioPopupHostPresent: Bool {
        get { self[FruitfolioPopupHostPresentKey.self] }
        set { self[FruitfolioPopupHostPresentKey.self] = newValue }
    }
}

struct FruitPopupHost<Content: View>: View {
    @Environment(\.fruitfolioPopupHostPresent) private var hasAncestorHost
    @AccessibilityFocusState private var paperMessageFocus: UUID?
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject
    private var popupCoordinator: PopupCoordinator

    @EnvironmentObject
    private var audioManager: AudioManager

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    @ViewBuilder
    let content: () -> Content

    @ViewBuilder
    var body: some View {
        if hasAncestorHost { content() }
        else { hostingBody }
    }

    private var hostingBody: some View {
        GeometryReader { proxy in
            ZStack {
                content()
                    .environment(\.fruitfolioPopupHostPresent, true)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .fruitfolioModalBlur(active: popupCoordinator.currentPopup != nil,
                                         reduceMotion: motionPreferences.reduceMotionActive)

                if let request =
                    popupCoordinator.currentPopup {

                    outsideTapLayer(
                        for: request
                    )
                    .zIndex(998)

                    if request.surface == .tapedWhite {
                        tapedWhitePopup(request, available: proxy.size)
                            .zIndex(999)
                    } else {
                        popupLayer(request: request, proxy: proxy)
                            .zIndex(999)
                    }

                }
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
        }

        /*
         Play popup-open audio only when the popup identity actually changes
         while this host is alive.

         Do not use task(id:) here: task(id:) also runs when the host itself
         appears. If the host is rebuilt while a popup is still stored in the
         coordinator, that can replay popupOpen even though no new popup opened.
        */
        .onChange(
            of: popupCoordinator.currentPopup?.id
        ) { oldID, newID in
            paperMessageFocus = nil
            guard
                newID != nil,
                newID != oldID,
                popupCoordinator.currentPopup != nil
            else {
                return
            }

            popupCoordinator.markMeasuring()
            popupCoordinator.markPresenting()
            popupCoordinator.markPresented()

            audioManager.play(
                .popupOpen
            )
        }

        .onChange(
            of: popupCoordinator.presentationState
        ) { _, state in

            guard state == .dismissing,
                  let dismissingPopupID = popupCoordinator.currentPopup?.id else {
                return
            }

            audioManager.play(
                .popupClose
            )

            Task { @MainActor in
                let delay: UInt64 =
                    motionPreferences.reduceMotionActive
                    ? 150_000_000
                    : 175_000_000

                do {
                    try await Task.sleep(nanoseconds: delay)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }

                /*
                 Do not finish an unrelated future popup dismissal if the
                 coordinator changed state while this task was sleeping.
                */
                guard
                    popupCoordinator.presentationState
                        == .dismissing
                else {
                    return
                }

                popupCoordinator.finishDismissal(expectedPopupID: dismissingPopupID)
            }
        }
    }

    // MARK: - Outside Tap Layer

    @ViewBuilder
    private func outsideTapLayer(
        for request: FruitPopupRequest
    ) -> some View {

        Color.black.opacity(FruitfolioModalBlurSpec.dimOpacity)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                if request.dismissBehavior == .tapOutside {
                    popupCoordinator.dismissCurrent(reason: .programmatic)
                }
            }
            .accessibilityHidden(true)
    }

    private func tapedWhitePopup(_ request: FruitPopupRequest, available: CGSize) -> some View {
        FruitfolioTapedWhitePopup {
            VStack(spacing: 12) {
                FruitfolioTranslatedContent(source: request.message) { display, _ in
                    FruitfolioSemanticText(markdown: display,
                        baseFont: .custom("Chalkboard SE", size: 15, relativeTo: .body), serious: true)
                        .textSelection(.enabled)
                        .accessibilityFocused($paperMessageFocus, equals: request.id)
                }
                .task(id: request.id) {
                    await Task.yield()
                    guard !Task.isCancelled, popupCoordinator.currentPopup?.id == request.id,
                          popupCoordinator.presentationState != .dismissing else { return }
                    paperMessageFocus = request.id
                }
                if let action = request.primaryAction { paperAction(action, primary: true) }
                if let action = request.secondaryAction { paperAction(action, primary: false) }
                if let action = request.tertiaryAction {
                    paperAction(action, primary: false, identifier: "fruitPopup.paper.action.tertiary")
                }
            }
            .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        }
        .frame(width: available.width, height: available.height)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("fruitPopup.tapedWhite")
        .accessibilityAction(.escape) {
            if request.dismissBehavior != .persistentUntilAcknowledged {
                popupCoordinator.dismissCurrent(reason: .programmatic)
            }
        }
    }

    private func paperAction(_ action: FruitPopupAction, primary: Bool, identifier: String? = nil) -> some View {
        FruitfolioControlPillButton(label: settings.localized(action.label)) {
            action.handler()
        }
        .accessibilityLabel(settings.localized(action.accessibilityLabel ?? action.label))
        .accessibilityIdentifier(identifier ?? (primary ? "fruitPopup.paper.action.primary" : "fruitPopup.paper.action.secondary"))
    }

    // MARK: - Popup Layer

    private func popupLayer(
        request: FruitPopupRequest,
        proxy: GeometryProxy
    ) -> some View {

        let safeTop =
            proxy.safeAreaInsets.top + 14

        let safeBottom =
            proxy.safeAreaInsets.bottom + 58

        let horizontalInset:
            CGFloat = 16

        let usableWidth =
            max(
                proxy.size.width
                    - (horizontalInset * 2),
                240
            )

        return VStack(
            spacing: 0
        ) {
            switch verticalBand(
                for:
                    request.positionPreference
            ) {

            case .top:
                popup(
                    request,
                    availableWidth:
                        usableWidth,
                    availableHeight: max(0, proxy.size.height - safeTop - safeBottom)
                )
                .frame(
                    maxWidth: .infinity,
                    alignment:
                        horizontalAlignment(
                            for:
                                request
                                    .positionPreference
                        )
                )
                .padding(
                    .top,
                    safeTop
                )

                Spacer(
                    minLength: 0
                )

            case .center:
                Spacer(
                    minLength: safeTop
                )

                popup(
                    request,
                    availableWidth:
                        usableWidth,
                    availableHeight: max(0, proxy.size.height - safeTop - safeBottom)
                )
                .frame(
                    maxWidth: .infinity,
                    alignment:
                        horizontalAlignment(
                            for:
                                request
                                    .positionPreference
                        )
                )

                Spacer(
                    minLength: safeBottom
                )

            case .bottom:
                Spacer(
                    minLength: 0
                )

                popup(
                    request,
                    availableWidth:
                        usableWidth,
                    availableHeight: max(0, proxy.size.height - safeTop - safeBottom)
                )
                .frame(
                    maxWidth: .infinity,
                    alignment:
                        horizontalAlignment(
                            for:
                                request
                                    .positionPreference
                        )
                )
                .padding(
                    .bottom,
                    safeBottom
                )
            }
        }
        .padding(
            .horizontal,
            horizontalInset
        )
        .frame(
            width: proxy.size.width,
            height: proxy.size.height
        )
        .transition(
            .opacity
        )
    }

    // MARK: - Popup

    private func popup(
        _ request: FruitPopupRequest,
        availableWidth: CGFloat,
        availableHeight: CGFloat
    ) -> some View {

        FruitPopupView(
            request: request,
            availableWidth:
                availableWidth,
            availableHeight: availableHeight,
            reduceMotion:
                motionPreferences
                    .reduceMotionActive
        )
        .accessibilityAddTraits(.isModal)
        .onTapGesture {
            if request.dismissBehavior
                == .tapPopup {

                popupCoordinator.dismissCurrent(
                    reason: .programmatic
                )
            }
        }
    }

    // MARK: - Positioning

    private enum VerticalBand {
        case top
        case center
        case bottom
    }

    private func verticalBand(
        for preference:
            FruitPopupPositionPreference
    ) -> VerticalBand {

        switch preference {

        case .top,
             .upperLeading,
             .upperTrailing:

            return .top

        case .centerLeading,
             .centerTrailing:

            return .center

        case .automatic,
             .lowerLeading,
             .lowerTrailing,
             .bottom:

            return .bottom
        }
    }

    private func horizontalAlignment(
        for preference:
            FruitPopupPositionPreference
    ) -> Alignment {

        switch preference {

        case .upperLeading,
             .centerLeading,
             .lowerLeading:

            return .leading

        case .upperTrailing,
             .centerTrailing,
             .lowerTrailing:

            return .trailing

        case .automatic,
             .top,
             .bottom:

            return .center
        }
    }
}

/// Native sheets/covers form a new presentation surface above the root overlay.
/// Give that surface one local host/coordinator so a citation dialog cannot be
/// rendered behind it or replay audio in both the sheet and app root.
struct FruitfolioPresentedPopupHost<Content: View>: View {
    @StateObject private var coordinator = PopupCoordinator()
    @ViewBuilder let content: () -> Content
    var body: some View {
        FruitPopupHost { content() }
            .environment(\.fruitfolioPopupHostPresent, false)
            .environmentObject(coordinator)
    }
}
