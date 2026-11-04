import SwiftUI

struct FruitPopupHost<Content: View>: View {
    @EnvironmentObject
    private var popupCoordinator: PopupCoordinator

    @EnvironmentObject
    private var audioManager: AudioManager

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    @ViewBuilder
    let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                content()
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .fruitfolioModalBlur(
                        active: popupCoordinator.currentPopup != nil && !usesHubTourTreatment,
                        reduceMotion: motionPreferences.reduceMotionActive
                    )
                    // The tour keeps its own approved appearance, but its
                    // invitation must still guard the underlying Hub controls.
                    .allowsHitTesting(popupCoordinator.currentPopup == nil)
                    .accessibilityHidden(popupCoordinator.currentPopup != nil)

                if let request =
                    popupCoordinator.currentPopup {

                    outsideTapLayer(
                        for: request
                    )
                    .zIndex(998)

                    popupLayer(
                        request: request,
                        proxy: proxy
                    )
                    .accessibilityAddTraits(.isModal)
                    .zIndex(999)
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

            guard state == .dismissing else {
                return
            }

            audioManager.play(
                .popupClose
            )

        }
        .task(id: popupCoordinator.presentationState == .dismissing ? popupCoordinator.currentPopup?.id : nil) {
            guard popupCoordinator.presentationState == .dismissing,
                  let expectedID = popupCoordinator.currentPopup?.id else { return }
            let delay: UInt64 = motionPreferences.reduceMotionActive ? 150_000_000 : 175_000_000
            do { try await Task.sleep(nanoseconds: delay) } catch { return }
            guard !Task.isCancelled else { return }
            // State alone is insufficient: a newer popup can also be dismissing.
            popupCoordinator.finishDismissal(expectedPopupID: expectedID)
        }
    }

    private var usesHubTourTreatment: Bool {
        popupCoordinator.currentPopup?.source?.hasPrefix("prompt07.") == true
    }

    // MARK: - Outside Tap Layer

    @ViewBuilder
    private func outsideTapLayer(
        for request: FruitPopupRequest
    ) -> some View {

        if request.dismissBehavior
            == .tapOutside {

            Color.clear
                .contentShape(
                    Rectangle()
                )
                .ignoresSafeArea()
                .onTapGesture {
                    popupCoordinator.dismissCurrent(
                        reason: .programmatic
                    )
                }
        }
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

        let usableWidth = max(0, proxy.size.width - (horizontalInset * 2))

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
                        usableWidth
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
                        usableWidth
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
                        usableWidth
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
        availableWidth: CGFloat
    ) -> some View {

        FruitPopupView(
            request: request,
            availableWidth:
                availableWidth,
            reduceMotion:
                motionPreferences
                    .reduceMotionActive
        )
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
