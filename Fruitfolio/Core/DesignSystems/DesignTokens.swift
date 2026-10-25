import SwiftUI

// PROMPT 02 — permanent semantic design tokens.
// Screens should request these tokens instead of scattering raw constants.
enum DesignTokens {
    enum ReferenceCanvas {
        static let width: CGFloat = 393
        static let height: CGFloat = 852
    }

    enum ColorToken {
        // Prompt 02 visual territory, centralized here rather than repeated in views.
        static let backgroundCream = Color(hex: 0xFFF9F0)
        static let primaryBurgundy = Color(hex: 0x800000)
        static let secondaryBurgundy = Color(hex: 0x800000)
        static let softWhite = Color(hex: 0xFFFDF8)

        // Sampled/normalized to harmonize with the supplied watercolor button art.
        static let mint = Color(hex: 0xCBDAC3)
        static let sage = Color(hex: 0xE2DEAF)
        static let peach = Color(hex: 0xFEDF9C)
        static let coral = Color(hex: 0xFDAC9F)
        static let paleYellow = Color(hex: 0xFEF0AD)
        static let lavender = Color(hex: 0xF1CDF4)
        static let dustyBlue = Color(hex: 0xB8CBD5)
        static let watercolorPink = Color(hex: 0xE8B8C4)

        static let disabledInk = Color(hex: 0x9B7C84)
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let majorBreak: CGFloat = 48

        static let iconToLabel: ClosedRange<CGFloat> = 6...10
        static let headingToBody: ClosedRange<CGFloat> = 8...12
        static let paragraph: ClosedRange<CGFloat> = 10...16
        static let section: ClosedRange<CGFloat> = 20...32
    }

    enum Layout {
        static let preferredHorizontalMargin: ClosedRange<CGFloat> = 20...24
        static let minimumHorizontalMargin: CGFloat = 16
        static let minimumHitTarget: CGFloat = 44

        // Readable bounded widths prevent Pro Max devices from simply inflating everything.
        static let compactReadingMaxWidth: CGFloat = 560
        static let standardReadingMaxWidth: CGFloat = 620

        // Default visual scale language — fractions of available width.
        static let tinyFleck: ClosedRange<CGFloat> = 0.03...0.06
        static let smallDecoration: ClosedRange<CGFloat> = 0.06...0.12
        static let tinyFunctionalIcon: ClosedRange<CGFloat> = 0.05...0.08
        static let normalFunctionalIllustration: ClosedRange<CGFloat> = 0.10...0.17
        static let fruitCharacter: ClosedRange<CGFloat> = 0.14...0.23
        static let mediumIllustration: ClosedRange<CGFloat> = 0.18...0.30
        static let majorBiologyIllustration: ClosedRange<CGFloat> = 0.32...0.48
        static let heroIllustration: ClosedRange<CGFloat> = 0.48...0.70
        static let bookEnvironment: ClosedRange<CGFloat> = 0.84...1.00
    }

    enum Typography {
        static let majorTitle: ClosedRange<CGFloat> = 26...32
        static let screenTitle: ClosedRange<CGFloat> = 22...26
        static let sectionHeading: ClosedRange<CGFloat> = 18...21
        static let button: ClosedRange<CGFloat> = 15...17
        static let body: ClosedRange<CGFloat> = 15...17
        static let secondary: ClosedRange<CGFloat> = 12...14
        static let metadata: ClosedRange<CGFloat> = 11...12
        static let minimumTinyLabel: CGFloat = 11
        static let preferredBody: CGFloat = 16
    }

    enum Motion {
        static let micro: ClosedRange<Double> = 0.080...0.180
        static let component: ClosedRange<Double> = 0.200...0.450
        static let storybook: ClosedRange<Double> = 0.600...1.000
        static let celebration: ClosedRange<Double> = 0.800...1.800

        static let microDefault: Double = 0.140
        static let componentDefault: Double = 0.280
        static let storybookDefault: Double = 0.750
        static let celebrationDefault: Double = 1.100
    }

    enum ZLayer {
        static let background: Double = 0
        static let environment: Double = 100
        static let decorativeArt: Double = 200
        static let functionalArt: Double = 300
        static let dynamicVisualization: Double = 400
        static let liveText: Double = 500
        static let interactionFeedback: Double = 600
        static let popupCharacter: Double = 700
        static let systemModal: Double = 800
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
