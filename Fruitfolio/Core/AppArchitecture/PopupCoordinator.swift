import Foundation
import SwiftUI
import Combine

@MainActor
final class PopupCoordinator: ObservableObject {

    enum PresentationState: Equatable {
        case idle
        case requested
        case measuring
        case presenting
        case visible
        case dismissing
    }

    @Published private(set) var currentPopup: FruitPopupRequest?
    @Published private(set) var presentationState: PresentationState = .idle

    private var queue: [FruitPopupRequest] = []
    private var activeDeduplicationKeys: Set<String> = []
    private var timedDismissTask: Task<Void, Never>?

    func request(_ request: FruitPopupRequest) {
        if let key = request.deduplicationKey {
            let duplicateIsActive = activeDeduplicationKeys.contains(key)
            let duplicateIsQueued = queue.contains {
                $0.deduplicationKey == key
            }

            guard !duplicateIsActive, !duplicateIsQueued else {
                return
            }
        }

        guard let currentPopup else {
            present(request)
            return
        }

        if request.priority > currentPopup.priority {
            enqueueReplacement(request)
            dismissCurrent(reason: .replacement)
        } else {
            enqueue(request)
        }
    }

    func markMeasuring() {
        guard currentPopup != nil else {
            presentationState = .idle
            return
        }

        presentationState = .measuring
    }

    func markPresenting() {
        guard currentPopup != nil else {
            presentationState = .idle
            return
        }

        presentationState = .presenting
    }

    func markPresented() {
        guard currentPopup != nil else {
            presentationState = .idle
            return
        }

        presentationState = .visible
        scheduleTimedDismissIfNeeded()
    }

    func dismissCurrent(
        reason: DismissReason = .programmatic
    ) {
        guard currentPopup != nil else {
            presentationState = .idle
            return
        }

        guard presentationState != .dismissing else {
            return
        }

        timedDismissTask?.cancel()
        timedDismissTask = nil

        presentationState = .dismissing
    }

    func finishDismissal() {
        timedDismissTask?.cancel()
        timedDismissTask = nil

        if let key = currentPopup?.deduplicationKey {
            activeDeduplicationKeys.remove(key)
        }

        currentPopup = nil
        presentationState = .idle

        presentNextEligible()
    }

    var blocksNavigation: Bool {
        guard let popup = currentPopup else { return false }
        switch popup.dismissBehavior {
        case .persistentUntilAcknowledged, .explicitActionOnly: return true
        default: return false
        }
    }

    func dismissForNavigation() {
        guard let popup = currentPopup else {
            return
        }

        switch popup.dismissBehavior {
        case .persistentUntilAcknowledged,
             .explicitActionOnly:
            return

        default:
            dismissCurrent(reason: .navigation)
        }
    }

    func clearLowPriorityQueue() {
        let removedRequests = queue.filter {
            $0.priority <= .success
        }

        queue.removeAll {
            $0.priority <= .success
        }

        removeDeduplicationKeys(
            for: removedRequests
        )
    }

    func resetForTesting() {
        timedDismissTask?.cancel()
        timedDismissTask = nil

        currentPopup = nil
        queue.removeAll()
        activeDeduplicationKeys.removeAll()

        presentationState = .idle
    }

    private func present(
        _ request: FruitPopupRequest
    ) {
        if let key = request.deduplicationKey {
            activeDeduplicationKeys.insert(key)
        }

        currentPopup = request
        presentationState = .requested
    }

    private func enqueue(
        _ request: FruitPopupRequest
    ) {
        queue.append(request)

        registerQueuedDeduplicationKey(
            for: request
        )

        sortQueueByPriority()
    }

    private func enqueueReplacement(
        _ request: FruitPopupRequest
    ) {
        let removedRequests = queue.filter {
            $0.priority < request.priority &&
            $0.priority <= .success
        }

        queue.removeAll {
            $0.priority < request.priority &&
            $0.priority <= .success
        }

        removeDeduplicationKeys(
            for: removedRequests
        )

        queue.insert(
            request,
            at: 0
        )

        registerQueuedDeduplicationKey(
            for: request
        )

        sortQueueByPriority()
    }

    private func presentNextEligible() {
        guard currentPopup == nil,
              !queue.isEmpty else {
            return
        }

        let next = queue.removeFirst()

        if let key = next.deduplicationKey {
            activeDeduplicationKeys.remove(key)
        }

        present(next)
    }

    private func sortQueueByPriority() {
        queue.sort {
            if $0.priority.rawValue ==
                $1.priority.rawValue {
                return false
            }

            return $0.priority.rawValue >
                $1.priority.rawValue
        }
    }

    private func registerQueuedDeduplicationKey(
        for request: FruitPopupRequest
    ) {
        if let key = request.deduplicationKey {
            activeDeduplicationKeys.insert(key)
        }
    }

    private func removeDeduplicationKeys(
        for requests: [FruitPopupRequest]
    ) {
        for request in requests {
            guard let key =
                    request.deduplicationKey else {
                continue
            }

            let keyIsCurrent =
                currentPopup?.deduplicationKey == key

            let keyIsStillQueued =
                queue.contains {
                    $0.deduplicationKey == key
                }

            if !keyIsCurrent &&
                !keyIsStillQueued {
                activeDeduplicationKeys.remove(key)
            }
        }
    }

    private func scheduleTimedDismissIfNeeded() {
        guard let popup = currentPopup else {
            return
        }

        guard case let .timed(seconds) =
                popup.dismissBehavior else {
            return
        }

        timedDismissTask?.cancel()

        let duration = max(
            0.1,
            seconds
        )

        timedDismissTask =
            Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(
                        for: .seconds(duration)
                    )
                } catch {
                    return
                }

                guard !Task.isCancelled else {
                    return
                }

                guard self?.currentPopup?.id ==
                        popup.id else {
                    return
                }

                self?.dismissCurrent(
                    reason: .timed
                )
            }
    }
}

enum DismissReason: Sendable {
    case action
    case outsideTap
    case popupTap
    case timed
    case navigation
    case programmatic
    case replacement
}
