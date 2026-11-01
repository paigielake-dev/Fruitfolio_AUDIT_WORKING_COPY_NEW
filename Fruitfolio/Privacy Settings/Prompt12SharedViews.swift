import SwiftUI

struct Prompt12PaperCard<Content: View>: View {
    let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            DesignTokens.ColorToken.backgroundCream.opacity(0.84),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .stroke(
                DesignTokens.ColorToken.secondaryBurgundy.opacity(0.13),
                lineWidth: 1
            )
        }
    }
}

struct Prompt12RouteHeader: View {
    let title: String
    let subtitle: String
    let assetName: String?
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                HStack {
                    BackControl {
                        onBack()
                    }

                    Spacer()
                }

                Text(title)
                    .font(.custom("Chalkboard SE", size: 25))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .fruitfolioProtectFromDecoration()
                    .padding(.horizontal, 58)
            }

            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }

            Text(subtitle)
                .font(.custom("Chalkboard SE", size: 12.5))
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .fruitfolioProtectFromDecoration()
                .frame(maxWidth: 300)
        }
        .padding(.top, 10)
    }
}

struct Prompt12NavigationRow: View {
    let title: String
    let detail: String?
    let assetName: String?
    let action: () -> Void

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    @EnvironmentObject
    private var audioManager: AudioManager

    var body: some View {
        Button {
            audioManager.play(.buttonSoftPop)
            action()
        } label: {
            HStack(spacing: 10) {
                if let assetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)
                }

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(title)
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 13
                            )
                        )
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens
                                .ColorToken
                                .primaryBurgundy
                        )

                    if let detail {
                        Text(detail)
                            .font(
                                .custom(
                                    "Chalkboard SE",
                                    size: 10.5
                                )
                            )
                            .foregroundStyle(
                                DesignTokens
                                    .ColorToken
                                    .secondaryBurgundy
                            )
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image("control_next")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 18,
                        height: 18
                    )
                    .accessibilityHidden(true)
            }
            .frame(
                minHeight:
                    DesignTokens
                        .Layout
                        .minimumHitTarget
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(
            Prompt12NavigationRowPopStyle(
                reduceMotion:
                    motionPreferences
                        .reduceMotionActive
            )
        )
        .accessibilityLabel(title)
    }
}

private struct Prompt12NavigationRowPopStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                reduceMotion
                    ? 1
                    : (
                        configuration.isPressed
                        ? 0.88
                        : 1
                    )
            )
            .offset(
                y:
                    reduceMotion
                    ? 0
                    : (
                        configuration.isPressed
                        ? 5
                        : 0
                    )
            )
            .rotationEffect(
                .degrees(
                    reduceMotion
                        ? 0
                        : (
                            configuration.isPressed
                            ? -1.2
                            : 0
                        )
                )
            )
            .brightness(
                reduceMotion
                    ? 0
                    : (
                        configuration.isPressed
                        ? -0.04
                        : 0
                    )
            )
            .animation(
                reduceMotion
                    ? .easeOut(
                        duration: 0.08
                    )
                    : .spring(
                        response: 0.20,
                        dampingFraction: 0.38,
                        blendDuration: 0
                    ),
                value:
                    configuration
                        .isPressed
            )
    }
}

struct Prompt12StatusPill: View {
    let text: String
    let assetName: String?

    var body: some View {
        HStack(spacing: 6) {
            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 18,
                        height: 18
                    )
                    .accessibilityHidden(true)
            }

            Text(text)
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 10.5
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens
                        .ColorToken
                        .primaryBurgundy
                )
        }
        .padding(
            .horizontal,
            10
        )
        .padding(
            .vertical,
            7
        )
        .background(
            DesignTokens
                .ColorToken
                .backgroundCream
                .opacity(0.90),
            in: Capsule()
        )
    }
}

struct Prompt12InfoText: View {
    let text: String

    init(
        _ text: String
    ) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 11.5
                )
            )
            .foregroundStyle(
                DesignTokens
                    .ColorToken
                    .secondaryBurgundy
            )
            .multilineTextAlignment(
                .leading
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )
    }
}


struct Prompt12VolumeRow: View {
    let title: String
    @Binding var value: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
            Slider(value: $value, in: 0...1)
                .tint(DesignTokens.ColorToken.primaryBurgundy)
                .accessibilityLabel(title)
                .accessibilityValue("\(Int(value * 100)) percent")
        }.frame(minHeight: 44)
    }
}
