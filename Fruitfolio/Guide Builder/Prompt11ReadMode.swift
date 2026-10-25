import SwiftUI

struct Prompt11ReadModeView: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let guideID: UUID
    let onClose: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var pageIndex = 0
    @State private var isClosing = false
    @State private var closeProgress: CGFloat = 0
    @State private var closeTask: Task<Void, Never>?

    private var guide: Prompt10Encyclopedia? {
        store.encyclopedia(id: guideID)
    }

    private var pages: [Prompt10SavedPage] {
        guard let guide else {
            return []
        }

        return guide.chapters
            .sorted { $0.order < $1.order }
            .flatMap { chapter in
                chapter.pages.sorted { $0.order < $1.order }
            }
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            VStack(spacing: 14) {
                header

                if pages.isEmpty {
                    Spacer()

                    Text("this guide is ready for its first page ♡")
                        .font(.custom("Chalkboard SE", size: 14))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .multilineTextAlignment(.center)

                    Spacer()

                } else {
                    ScrollView {
                        Prompt11SavedPagePaper(
                            page: pages[safe: pageIndex] ?? pages[0],
                            pageNumber: pageIndex + 1,
                            sourceStillExists: sourceExists(
                                for: pages[safe: pageIndex] ?? pages[0]
                            ),
                            onAddNote: nil
                        )
                        .transition(
                            motionPreferences.reduceMotionActive
                                ? .opacity
                                : .opacity.combined(
                                    with: .move(edge: .trailing)
                                )
                        )
                    }

                    pageControls
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .opacity(contentOpacity)
            .scaleEffect(contentScale)
            .allowsHitTesting(!isClosing)

            if isClosing {
                localBookClosingOverlay
                    .zIndex(20)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: pages.count) { _, newCount in
            if newCount == 0 {
                pageIndex = 0
            } else if pageIndex >= newCount {
                pageIndex = max(newCount - 1, 0)
            }
        }
        .onDisappear {
            closeTask?.cancel()
        }
    }

    private var contentOpacity: Double {
        guard isClosing else {
            return 1
        }

        let progress = Double(closeProgress)
        return max(0, 1 - (progress * 1.35))
    }

    private var contentScale: CGFloat {
        guard isClosing, !motionPreferences.reduceMotionActive else {
            return 1
        }

        let shrinkAmount: CGFloat = 0.015 * closeProgress
        return CGFloat(1.0) - shrinkAmount
    }

    private var header: some View {
        HStack {
            Prompt11GuideIconButton(
                assetName: "guide_back",
                identificationWord: "back",
                accessibilityLabel: "Back",
                reduceMotion: motionPreferences.reduceMotionActive,
                width: 34,
                action: requestClose
            )

            Spacer()

            Text(guide?.name ?? "my guide")
                .font(.custom("Chalkboard SE", size: 20))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Spacer()

            Color.clear
                .frame(
                    width: DesignTokens.Layout.minimumHitTarget,
                    height: DesignTokens.Layout.minimumHitTarget
                )
        }
    }

    private var localBookClosingOverlay: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.94, 430)

            ZStack {
                DesignTokens.ColorToken.backgroundCream
                    .opacity(0.94)
                    .ignoresSafeArea()

                FruitfolioImage(id: .book_open_blank)
                    .scaledToFit()
                    .frame(width: width)
                    .opacity(stageOpacity(center: 0.08, width: 0.26))

                FruitfolioImage(id: .book_slightly_open_logo)
                    .scaledToFit()
                    .frame(width: width * 0.72)
                    .opacity(stageOpacity(center: 0.52, width: 0.34))

                FruitfolioImage(id: .book_closed_logo)
                    .scaledToFit()
                    .frame(width: width * 0.62)
                    .opacity(
                        smoothStep(
                            from: 0.62,
                            to: 0.92,
                            value: closeProgress
                        )
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(true)
    }

    private func requestClose() {
        guard !isClosing else {
            return
        }

        isClosing = true
        closeTask?.cancel()

        if motionPreferences.reduceMotionActive {
            audioManager.play(.bookClose)

            withAnimation(.easeOut(duration: 0.14)) {
                closeProgress = 1
            }

            closeTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))

                guard !Task.isCancelled else {
                    return
                }

                onClose()
            }

            return
        }

        audioManager.play(.bookClose)

        withAnimation(.easeInOut(duration: 0.48)) {
            closeProgress = 1
        }

        closeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))

            guard !Task.isCancelled else {
                return
            }

            onClose()
        }
    }

    private func stageOpacity(
        center: CGFloat,
        width: CGFloat
    ) -> Double {
        let distance = abs(closeProgress - center)
        let normalizedDistance = distance / max(width, 0.001)

        return Double(
            max(
                CGFloat.zero,
                CGFloat(1.0) - normalizedDistance
            )
        )
    }

    private func smoothStep(
        from start: CGFloat,
        to end: CGFloat,
        value: CGFloat
    ) -> Double {
        let denominator = max(end - start, 0.001)
        let unclamped = (value - start) / denominator
        let t = min(max(unclamped, 0), 1)

        let result =
            t
            * t
            * (
                CGFloat(3.0)
                - (CGFloat(2.0) * t)
            )

        return Double(result)
    }

    private var pageControls: some View {
        HStack(spacing: 18) {
            Button("previous page") {
                guard pageIndex > 0 else {
                    return
                }

                audioManager.play(.pageTurn)

                withAnimation(pageAnimation) {
                    pageIndex -= 1
                }
            }
            .disabled(pageIndex == 0)
            .frame(
                minHeight: DesignTokens.Layout.minimumHitTarget
            )

            Text("\(pageIndex + 1) / \(pages.count)")
                .font(.custom("Chalkboard SE", size: 10.5))
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )

            Button("next page") {
                guard pageIndex < pages.count - 1 else {
                    return
                }

                audioManager.play(.pageTurn)

                withAnimation(pageAnimation) {
                    pageIndex += 1
                }
            }
            .disabled(pageIndex >= pages.count - 1)
            .frame(
                minHeight: DesignTokens.Layout.minimumHitTarget
            )
        }
        .font(.custom("Chalkboard SE", size: 11.5))
        .fontWeight(.bold)
        .foregroundStyle(
            DesignTokens.ColorToken.primaryBurgundy
        )
    }

    private func sourceExists(
        for page: Prompt10SavedPage
    ) -> Bool {
        guard let sourceKey = page.sourceSavedPageID else {
            return true
        }

        return store.prompt11SourcePage(
            sourceKey: sourceKey
        ) != nil
    }

    private var pageAnimation: Animation {
        motionPreferences.reduceMotionActive
            ? .easeOut(duration: 0.14)
            : .easeOut(duration: 0.24)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
