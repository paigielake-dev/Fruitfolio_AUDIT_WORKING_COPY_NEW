import CoreGraphics

/// Single geometry authority for Prompt 04.
///
/// The Intro keeps every physical book state on one exact viewport-center axis
/// and as large as possible while remaining fully visible. No state-specific
/// vertical or horizontal nudge is permitted during the four book-state beats.
/// After the fully open state settles, the same
/// open-book artwork zooms toward its right page. The final Hub then resolves to
/// a standalone founder-painted blank paper surface with no book visible.
enum Prompt04BookLayout {
    static let closedBookAspectRatio: CGFloat = 627.0 / 812.0
    static let brandedBookAspectRatio: CGFloat = 644.0 / 795.0
    static let slightlyOpenBookAspectRatio: CGFloat = 711.0 / 805.0
    static let openBookAspectRatio: CGFloat = 989.0 / 596.0
    static let hubPaperAspectRatio: CGFloat = 851.0 / 1317.0

    /// Safe sample area of the right-hand page in book_open_blank.png.
    /// This avoids the binding, page curl, and outer watercolor boundary while
    /// the camera moves into the page.
    private static let rightPageSafeXMin: CGFloat = 0.555
    private static let rightPageSafeXMax: CGFloat = 0.925
    private static let rightPageSafeYMin: CGFloat = 0.090
    private static let rightPageSafeYMax: CGFloat = 0.885

    struct Metrics: Equatable {
        let viewportWidth: CGFloat
        let viewportHeight: CGFloat

        let closedBookWidth: CGFloat
        let brandedBookWidth: CGFloat
        let slightlyOpenBookWidth: CGFloat
        let centeredOpenBookWidth: CGFloat
        let centeredOpenBookHeight: CGFloat

        let focusedBookWidth: CGFloat
        let focusedBookHeight: CGFloat
        let focusedBookOffsetX: CGFloat
        let focusedBookOffsetY: CGFloat

        let hubContentWidth: CGFloat
        let hubContentHeight: CGFloat
        let hubHorizontalPadding: CGFloat
        let hubTopPadding: CGFloat
        let hubBottomPadding: CGFloat
        let hubGridGap: CGFloat
        let hubGridColumnWidth: CGFloat
        let hubButtonHeight: CGFloat
        let utilityItemWidth: CGFloat
        let utilityIconSize: CGFloat
    }

    static func metrics(for viewport: CGSize) -> Metrics {
        let width = max(1, viewport.width)
        let height = max(1, viewport.height)

        // Keep a tiny guaranteed edge guard. The art remains the dominant focus,
        // but no state may drift off-screen or touch the physical display edge.
        let edgeGuard = max(8, min(14, width * 0.026))
        let availableWidth = max(1, width - (edgeGuard * 2))
        let availableHeight = max(1, height * 0.80)

        func maximalCenteredWidth(aspectRatio: CGFloat) -> CGFloat {
            let byWidth = availableWidth
            let byHeight = availableHeight * aspectRatio
            return max(1, min(byWidth, byHeight))
        }

        let closedBookWidth = maximalCenteredWidth(aspectRatio: closedBookAspectRatio)
        let brandedBookWidth = maximalCenteredWidth(aspectRatio: brandedBookAspectRatio)
        let slightlyOpenBookWidth = maximalCenteredWidth(aspectRatio: slightlyOpenBookAspectRatio)
        let centeredOpenBookWidth = maximalCenteredWidth(aspectRatio: openBookAspectRatio)
        let centeredOpenBookHeight = max(1, centeredOpenBookWidth / openBookAspectRatio)

        // Derive the zoom from the right-page safe rectangle. The rectangle is
        // enlarged enough to cover the viewport, ensuring the user perceives a
        // camera move into paper rather than a second screen sliding in.
        let normalizedPageWidth = max(0.001, rightPageSafeXMax - rightPageSafeXMin)
        let normalizedPageHeight = max(0.001, rightPageSafeYMax - rightPageSafeYMin)
        let focusedWidthForViewport = width / normalizedPageWidth
        let focusedHeightForViewport = height / normalizedPageHeight
        let focusedBookWidthFromHeight = focusedHeightForViewport * openBookAspectRatio
        let focusedBookWidth = max(focusedWidthForViewport, focusedBookWidthFromHeight)
        let focusedBookHeight = max(1, focusedBookWidth / openBookAspectRatio)

        let rightPageCenterX = (rightPageSafeXMin + rightPageSafeXMax) * 0.5
        let rightPageCenterY = (rightPageSafeYMin + rightPageSafeYMax) * 0.5
        let focusedBookOffsetX = -((rightPageCenterX - 0.5) * focusedBookWidth)
        let focusedBookOffsetY = -((rightPageCenterY - 0.5) * focusedBookHeight)

        // Final Hub uses a standalone paper texture that aspect-fills the viewport.
        // Live content stays inside safe-area-sized geometry rather than depending
        // on the cropped paper edge location.
        let hubHorizontalPadding = max(16, min(20, width * 0.045))
        let hubTopPadding = max(18, min(28, height * 0.030))
        let hubBottomPadding = max(16, min(24, height * 0.026))
        let hubContentWidth = max(1, width - (hubHorizontalPadding * 2))
        let hubContentHeight = max(1, height - hubTopPadding - hubBottomPadding)

        let hubGridGap = max(8, min(10, width * 0.024))
        let hubGridColumnWidth = max(1, (hubContentWidth - hubGridGap) * 0.5)
        let hubButtonHeight = max(72, min(90, height * 0.098))
        let utilityItemWidth = max(1, hubContentWidth / 3)
        let utilityIconSize = max(34, min(42, width * 0.098))

        return Metrics(
            viewportWidth: width,
            viewportHeight: height,
            closedBookWidth: closedBookWidth,
            brandedBookWidth: brandedBookWidth,
            slightlyOpenBookWidth: slightlyOpenBookWidth,
            centeredOpenBookWidth: centeredOpenBookWidth,
            centeredOpenBookHeight: centeredOpenBookHeight,
            focusedBookWidth: focusedBookWidth,
            focusedBookHeight: focusedBookHeight,
            focusedBookOffsetX: focusedBookOffsetX,
            focusedBookOffsetY: focusedBookOffsetY,
            hubContentWidth: hubContentWidth,
            hubContentHeight: hubContentHeight,
            hubHorizontalPadding: hubHorizontalPadding,
            hubTopPadding: hubTopPadding,
            hubBottomPadding: hubBottomPadding,
            hubGridGap: hubGridGap,
            hubGridColumnWidth: hubGridColumnWidth,
            hubButtonHeight: hubButtonHeight,
            utilityItemWidth: utilityItemWidth,
            utilityIconSize: utilityIconSize
        )
    }
}
