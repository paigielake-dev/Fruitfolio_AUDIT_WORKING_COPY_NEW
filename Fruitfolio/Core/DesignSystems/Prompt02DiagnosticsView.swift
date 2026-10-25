import SwiftUI

struct Prompt02DiagnosticsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let swatches: [(String, Color)] = [
        ("cream", DesignTokens.ColorToken.backgroundCream),
        ("burgundy", DesignTokens.ColorToken.primaryBurgundy),
        ("mint", DesignTokens.ColorToken.mint),
        ("sage", DesignTokens.ColorToken.sage),
        ("peach", DesignTokens.ColorToken.peach),
        ("coral", DesignTokens.ColorToken.coral),
        ("yellow", DesignTokens.ColorToken.paleYellow),
        ("lavender", DesignTokens.ColorToken.lavender),
        ("dusty blue", DesignTokens.ColorToken.dustyBlue)
    ]

    var body: some View {
        FruitfolioSafeContent {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                Text("Prompt 02 Diagnostics")
                    .fruitfolioText(.majorTitle)

                Text("Global Design System")
                    .fruitfolioText(.secondary, secondary: true)

                diagnosticCard
                paletteCard
                scaleCard
                typographyCard
                motionCard
            }
        }
    }

    private var diagnosticCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            row("Reference", "393 × 852 design reference")
            row("Minimum margin", "16 pt")
            row("Preferred margin", "20–24 pt")
            row("Hit target", "44 × 44 pt")
            row("Dynamic Type", String(describing: dynamicTypeSize))
            row("Reduce Motion", reduceMotion ? "ON" : "OFF")
            row("Comic Sans MS", FruitfolioTypography.comicSansMSAvailable ? "available" : "DEPENDENCY NOT PRESENT")
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.ColorToken.softWhite.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var paletteCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Semantic palette")
                .fruitfolioText(.sectionHeading)

            ForEach(swatches, id: \.0) { name, color in
                HStack(spacing: DesignTokens.Spacing.sm) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color)
                        .frame(width: 48, height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(DesignTokens.ColorToken.primaryBurgundy.opacity(0.18), lineWidth: 1)
                        )
                    Text(name)
                        .fruitfolioText(.body)
                }
            }
        }
    }

    private var scaleCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Responsive scale guardrails")
                .fruitfolioText(.sectionHeading)
            Text("tiny fleck 3–6% • decoration 6–12% • icon 5–8% • functional 10–17% • character 14–23% • medium 18–30% • biology 32–48% • hero 48–70% • book/environment 84–100%")
                .fruitfolioText(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var typographyCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Major title 26–32")
                .fruitfolioText(.majorTitle)
            Text("Screen title 22–26")
                .fruitfolioText(.screenTitle)
            Text("Section heading 18–21")
                .fruitfolioText(.sectionHeading)
            Text("Body reading text around 16 pt. Long medical/scientific copy stays left aligned, readable, and allowed to wrap rather than being shrunk into art.")
                .fruitfolioText(.body)
                .fixedSize(horizontal: false, vertical: true)
            Text("Secondary 12–14")
                .fruitfolioText(.secondary, secondary: true)
            Text("Metadata 11–12")
                .fruitfolioText(.metadata, secondary: true)
        }
    }

    private var motionCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Motion categories")
                .fruitfolioText(.sectionHeading)
            row("Micro", "80–180 ms")
            row("Component", "200–450 ms")
            row("Storybook", "600–1,000 ms")
            row("Celebration", "800–1,800 ms")
        }
    }

    private func row(_ name: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(name)
                .fruitfolioText(.body)
            Spacer(minLength: DesignTokens.Spacing.sm)
            Text(value)
                .fruitfolioText(.secondary, secondary: true)
                .multilineTextAlignment(.trailing)
        }
    }
}
