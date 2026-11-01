//
//  Prompt08GlobalControls.swift
//  Fruitfolio
//
//  Created by Paul Hudson on 08/04/2023.
//

import SwiftUI

// MARK: - WatercolorPrimaryButton

/// Compatibility entry point: all existing primary-action call sites now use
/// the original control-pill artwork and the canonical interaction path.
struct WatercolorPrimaryButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        FruitfolioControlPillButton(label: label, action: action)
    }
}

// MARK: - WatercolorSecondaryButton

struct WatercolorSecondaryButton: View {
    let label: String
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
            Text(label)
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 14,
                        relativeTo: .body
                    )
                )
                .foregroundColor(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(
                    minHeight: DesignTokens.Layout.minimumHitTarget,
                    alignment: .center
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .stroke(
                        DesignTokens.ColorToken
                            .primaryBurgundy
                            .opacity(0.8),
                        lineWidth: 1.6
                    )
                )
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive
            )
        )
        .accessibilityLabel(label)
    }
}

// MARK: - FruitfolioControlPillButton

/// Canonical Fruitfolio pill action using a coded shell derived from the
/// control_pill_outline.png proportions. The live label stays centered and the
/// shell grows vertically when longer text or Dynamic Type needs more room.
struct FruitfolioControlPillButton: View {
    let label: String
    var playsSound = true
    let action: () -> Void

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    @EnvironmentObject
    private var audioManager: AudioManager

    var body: some View {
        Button {
            if playsSound { audioManager.play(.buttonSoftPop) }
            action()
        } label: {
            Text(label)
                .font(.custom("Chalkboard SE", size: 15, relativeTo: .headline))
                .fontWeight(.semibold)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 46)
                .padding(.vertical, 20)
                .frame(maxWidth: 292, minHeight: 82, alignment: .center)
                .background { FruitfolioControlPillArtwork() }
            .contentShape(Rectangle())
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive
            )
        )
        .accessibilityLabel(label)
    }
}

// MARK: - FruitfolioLargeCard

/// Canonical Fruitfolio large card using a coded shell derived from the
/// control_large_card.png proportions. The card is content-driven and grows
/// vertically with its contents without distorting the reference artwork.
struct FruitfolioLargeCard<Content: View>: View {
    private let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        VStack(
            alignment: .center,
            spacing: 14
        ) {
            content
        }
        .multilineTextAlignment(.center)
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
        .padding(.horizontal, 28)
        .padding(.vertical, 28)
        .frame(
            maxWidth: 330,
            minHeight: 180,
            alignment: .center
        )
        .background {
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
            .fill(
                DesignTokens.ColorToken.backgroundCream
                    .opacity(0.985)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
                .stroke(
                    DesignTokens.ColorToken.primaryBurgundy
                        .opacity(0.82),
                    lineWidth: 1.8
                )
            }
            .shadow(
                color: Color.black.opacity(0.045),
                radius: 3,
                x: 0,
                y: 1
            )
        }
        .accessibilityElement(children: .contain)
    }
}


// MARK: - FruitfolioTapedPaperPopup

/// Code-built popup inspired by popup_taped_white.png.
/// The paper body is content-driven, so it expands and contracts naturally
/// without stretching artwork. The paperclip remains decorative.
struct FruitfolioTapedPaperPopup<Content: View>: View {
    private let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        VStack(
            alignment: .center,
            spacing: 0
        ) {
            content
        }
        .multilineTextAlignment(.center)
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
        .padding(.horizontal, 30)
        .padding(.top, 42)
        .padding(.bottom, 30)
        .frame(
            maxWidth: 330,
            alignment: .center
        )
        .background {
            ZStack {
                FruitfolioTornPaperShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 1.0,
                                    green: 0.995,
                                    blue: 0.975
                                ),
                                Color(
                                    red: 0.985,
                                    green: 0.978,
                                    blue: 0.955
                                )
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                FruitfolioPaperWrinkleOverlay()
                    .clipShape(
                        FruitfolioTornPaperShape()
                    )

                FruitfolioTornPaperShape()
                    .stroke(
                        Color(
                            red: 0.80,
                            green: 0.76,
                            blue: 0.69
                        )
                        .opacity(0.28),
                        lineWidth: 0.85
                    )
            }
            .shadow(
                color: Color.black.opacity(0.075),
                radius: 7,
                x: 0,
                y: 4
            )
        }
        .overlay(alignment: .top) {
            FruitfolioPaperTape()
                .frame(
                    width: 176,
                    height: 48
                )
                .offset(y: -22)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .topTrailing) {
            Image("popup_paperclip")
                .resizable()
                .scaledToFit()
                .frame(
                    width: 30,
                    height: 43
                )
                .rotationEffect(
                    .degrees(7)
                )
                .offset(
                    x: -18,
                    y: 19
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .padding(.top, 24)
        .accessibilityElement(
            children: .contain
        )
    }
}

private struct FruitfolioTornPaperShape: Shape {
    func path(
        in rect: CGRect
    ) -> Path {
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height

        var path = Path()

        path.move(
            to: CGPoint(
                x: x + w * 0.055,
                y: y + h * 0.012
            )
        )

        // Top edge
        path.addLine(to: CGPoint(x: x + w * 0.18, y: y + h * 0.006))
        path.addLine(to: CGPoint(x: x + w * 0.34, y: y + h * 0.014))
        path.addLine(to: CGPoint(x: x + w * 0.50, y: y + h * 0.004))
        path.addLine(to: CGPoint(x: x + w * 0.68, y: y + h * 0.013))
        path.addLine(to: CGPoint(x: x + w * 0.84, y: y + h * 0.007))
        path.addLine(to: CGPoint(x: x + w * 0.956, y: y + h * 0.017))

        // Right edge
        path.addLine(to: CGPoint(x: x + w * 0.985, y: y + h * 0.12))
        path.addLine(to: CGPoint(x: x + w * 0.977, y: y + h * 0.29))
        path.addLine(to: CGPoint(x: x + w * 0.989, y: y + h * 0.47))
        path.addLine(to: CGPoint(x: x + w * 0.978, y: y + h * 0.66))
        path.addLine(to: CGPoint(x: x + w * 0.986, y: y + h * 0.83))
        path.addLine(to: CGPoint(x: x + w * 0.965, y: y + h * 0.978))

        // Bottom edge
        path.addLine(to: CGPoint(x: x + w * 0.83, y: y + h * 0.988))
        path.addLine(to: CGPoint(x: x + w * 0.67, y: y + h * 0.979))
        path.addLine(to: CGPoint(x: x + w * 0.51, y: y + h * 0.991))
        path.addLine(to: CGPoint(x: x + w * 0.34, y: y + h * 0.982))
        path.addLine(to: CGPoint(x: x + w * 0.18, y: y + h * 0.990))
        path.addLine(to: CGPoint(x: x + w * 0.045, y: y + h * 0.973))

        // Left edge
        path.addLine(to: CGPoint(x: x + w * 0.018, y: y + h * 0.84))
        path.addLine(to: CGPoint(x: x + w * 0.026, y: y + h * 0.66))
        path.addLine(to: CGPoint(x: x + w * 0.015, y: y + h * 0.48))
        path.addLine(to: CGPoint(x: x + w * 0.026, y: y + h * 0.29))
        path.addLine(to: CGPoint(x: x + w * 0.017, y: y + h * 0.12))

        path.closeSubpath()
        return path
    }
}

private struct FruitfolioPaperWrinkleOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Path { path in
                    path.move(
                        to: CGPoint(
                            x: size.width * 0.07,
                            y: size.height * 0.23
                        )
                    )
                    path.addCurve(
                        to: CGPoint(
                            x: size.width * 0.93,
                            y: size.height * 0.34
                        ),
                        control1: CGPoint(
                            x: size.width * 0.31,
                            y: size.height * 0.17
                        ),
                        control2: CGPoint(
                            x: size.width * 0.64,
                            y: size.height * 0.42
                        )
                    )
                }
                .stroke(
                    Color.white.opacity(0.30),
                    lineWidth: 1.1
                )

                Path { path in
                    path.move(
                        to: CGPoint(
                            x: size.width * 0.24,
                            y: size.height * 0.06
                        )
                    )
                    path.addCurve(
                        to: CGPoint(
                            x: size.width * 0.37,
                            y: size.height * 0.93
                        ),
                        control1: CGPoint(
                            x: size.width * 0.16,
                            y: size.height * 0.34
                        ),
                        control2: CGPoint(
                            x: size.width * 0.48,
                            y: size.height * 0.65
                        )
                    )
                }
                .stroke(
                    Color.black.opacity(0.025),
                    lineWidth: 1.2
                )

                Path { path in
                    path.move(
                        to: CGPoint(
                            x: size.width * 0.77,
                            y: size.height * 0.10
                        )
                    )
                    path.addCurve(
                        to: CGPoint(
                            x: size.width * 0.64,
                            y: size.height * 0.90
                        ),
                        control1: CGPoint(
                            x: size.width * 0.91,
                            y: size.height * 0.38
                        ),
                        control2: CGPoint(
                            x: size.width * 0.55,
                            y: size.height * 0.61
                        )
                    )
                }
                .stroke(
                    Color.white.opacity(0.22),
                    lineWidth: 0.9
                )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FruitfolioPaperTape: View {
    var body: some View {
        RoundedRectangle(
            cornerRadius: 4,
            style: .continuous
        )
        .fill(
            LinearGradient(
                colors: [
                    Color(
                        red: 0.96,
                        green: 0.86,
                        blue: 0.66
                    )
                    .opacity(0.78),
                    Color(
                        red: 0.97,
                        green: 0.90,
                        blue: 0.74
                    )
                    .opacity(0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 4,
                style: .continuous
            )
            .stroke(
                Color(
                    red: 0.70,
                    green: 0.61,
                    blue: 0.47
                )
                .opacity(0.16),
                lineWidth: 0.7
            )
        }
        .rotationEffect(
            .degrees(-3.5)
        )
        .shadow(
            color: Color.black.opacity(0.055),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

// MARK: - BackControl

struct BackControl: View {
    let action: () -> Void

    @EnvironmentObject
    private var audioManager: AudioManager

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    var body: some View {
        FruitfolioIconActionSurface(
            identificationWord: "back",
            accessibilityLabel: "Back",
            action: {
                audioManager.play(.buttonSoftPop)
                action()
            }
        ) {
            Image(systemName: "chevron.left")
                .font(.title2.weight(.semibold))
                .foregroundColor(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive
            )
        )
    }
}

// MARK: - CloseControl

struct CloseControl: View {
    let action: () -> Void

    @EnvironmentObject
    private var audioManager: AudioManager

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    var body: some View {
        FruitfolioIconActionSurface(
            identificationWord: "close",
            accessibilityLabel: "Close",
            action: {
                audioManager.play(.buttonSoftPop)
                action()
            }
        ) {
            Image(systemName: "xmark")
                .font(.title2.weight(.semibold))
                .foregroundColor(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive
            )
        )
    }
}

// MARK: - AddControl

struct AddControl: View {
    let action: () -> Void

    @EnvironmentObject
    private var audioManager: AudioManager

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    var body: some View {
        FruitfolioIconActionSurface(
            identificationWord: "add",
            accessibilityLabel: "Add",
            action: {
                audioManager.play(.buttonSoftPop)
                action()
            }
        ) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive
            )
        )
    }
}

// MARK: - ConfirmControl

struct ConfirmControl: View {
    let action: () -> Void

    @EnvironmentObject
    private var audioManager: AudioManager

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    var body: some View {
        FruitfolioIconActionSurface(
            identificationWord: "confirm",
            accessibilityLabel: "Confirm",
            action: {
                audioManager.play(.buttonSoftPop)
                action()
            }
        ) {
            Image(systemName: "checkmark")
                .font(.title2.weight(.semibold))
                .foregroundColor(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive
            )
        )
    }
}

// MARK: - ChoiceCircle

struct ChoiceCircle: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .strokeBorder(
                DesignTokens.ColorToken.primaryBurgundy,
                lineWidth: isSelected ? 4 : 2
            )
            .background(
                Circle()
                    .fill(
                        isSelected
                            ? DesignTokens.ColorToken.primaryBurgundy
                            : Color.clear
                    )
            )
            .frame(width: 24, height: 24)
            .animation(
                .easeInOut(duration: 0.2),
                value: isSelected
            )
    }
}

// MARK: - PageTurnTransition

struct PageTurnTransition: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isActive ? 0 : 90),
                axis: (x: 0, y: 1, z: 0),
                anchor: .leading,
                perspective: 0.6
            )
            .opacity(isActive ? 1 : 0)
            .animation(
                .easeInOut(duration: 0.5),
                value: isActive
            )
    }
}

// MARK: - WatercolorBottomSheet

struct WatercolorBottomSheet<Content: View>: View {
    let title: String
    let content: Content
    let onClose: () -> Void

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    @State
    private var isVisible = false

    init(
        title: String,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 20,
                            relativeTo: .headline
                        )
                    )
                    .foregroundColor(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                Spacer()

                CloseControl(action: onClose)
            }
            .padding()

            Divider()

            content
                .padding()
        }
        .background(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(Color.white)
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 20,
                x: 0,
                y: -10
            )
        )
        .padding()
        .transition(
            .move(edge: .bottom)
                .combined(with: .opacity)
        )
        .animation(
            motionPreferences.reduceMotionActive
                ? .easeOut(duration: 0.2)
                : .spring(
                    response: 0.4,
                    dampingFraction: 0.7,
                    blendDuration: 0
                ),
            value: isVisible
        )
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - InfoTooltip

struct InfoTooltip: View {
    let message: String

    @State
    private var isVisible = false

    var body: some View {
        if isVisible {
            Text(message)
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 12,
                        relativeTo: .caption
                    )
                )
                .foregroundColor(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .padding(8)
                .background(
                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                    .fill(Color.white)
                    .shadow(radius: 6)
                )
                .transition(.opacity)
                .zIndex(1)
        }
    }
}

// MARK: - Watercolor toggle

private struct FruitfolioWatercolorToggleStyle: ToggleStyle {
    let reduceMotion: Bool
    let onUserToggle: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        Button {
            // IMPORTANT:
            // Update the actual Binding BEFORE requesting the sound.
            // This lets the tap that enables Sound Effects immediately
            // pass AudioManager's enabled-state check.
            withAnimation(
                reduceMotion
                    ? .easeOut(duration: 0.08)
                    : .spring(
                        response: 0.24,
                        dampingFraction: 0.72,
                        blendDuration: 0
                    )
            ) {
                configuration.isOn.toggle()
            }

            onUserToggle()
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                ZStack {
                    Capsule(style: .continuous)
                        .fill(
                            Color(
                                red: 0.79,
                                green: 0.76,
                                blue: 0.70
                            )
                            .opacity(0.72)
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    Color(
                                        red: 0.48,
                                        green: 0.40,
                                        blue: 0.34
                                    )
                                    .opacity(0.38),
                                    lineWidth: 1.2
                                )
                        }
                        .overlay {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.16),
                                            Color.clear,
                                            Color(
                                                red: 0.50,
                                                green: 0.42,
                                                blue: 0.36
                                            )
                                            .opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                    Circle()
                        .stroke(
                            DesignTokens.ColorToken
                                .primaryBurgundy
                                .opacity(0.82),
                            lineWidth: 4
                        )
                        .frame(
                            width: 18,
                            height: 18
                        )
                        .offset(x: 14)
                        .opacity(
                            configuration.isOn
                                ? 0.18
                                : 1
                        )

                    Circle()
                        .fill(
                            Color(
                                red: 1.0,
                                green: 0.985,
                                blue: 0.95
                            )
                        )
                        .overlay {
                            Circle()
                                .stroke(
                                    Color(
                                        red: 0.58,
                                        green: 0.51,
                                        blue: 0.44
                                    )
                                    .opacity(0.32),
                                    lineWidth: 0.8
                                )
                        }
                        .shadow(
                            color: Color.black.opacity(0.12),
                            radius: 1.5,
                            x: 0,
                            y: 1
                        )
                        .frame(
                            width: 30,
                            height: 30
                        )
                        .offset(
                            x: configuration.isOn
                                ? 13
                                : -13
                        )
                }
                .frame(
                    width: 58,
                    height: 36
                )
            }
            .frame(
                minHeight:
                    DesignTokens.Layout.minimumHitTarget
            )
            .contentShape(Rectangle())
        }

        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: reduceMotion
            )
        )
    }
}

struct WatercolorToggle: View {
    let label: String

    @Binding
    var isOn: Bool

    var isDisabled: Bool = false

    @EnvironmentObject
    private var audioManager: AudioManager

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 14,
                        relativeTo: .body
                    )
                )
                .foregroundStyle(
                    isDisabled
                        ? DesignTokens.ColorToken.disabledInk
                        : DesignTokens.ColorToken.primaryBurgundy
                )
        }
        .toggleStyle(
            FruitfolioWatercolorToggleStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive,
                onUserToggle: {
                    audioManager.play(.buttonSoftPop)
                }
            )
        )
        .disabled(isDisabled)
        .accessibilityLabel(Text(label))
        .accessibilityValue(
            Text(isOn ? "on" : "off")
        )
    }
}

// MARK: - BookmarkButton

struct BookmarkButton: View {
    @Binding
    var isBookmarked: Bool

    @EnvironmentObject
    private var audioManager: AudioManager

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    var body: some View {
        FruitfolioIconActionSurface(
            identificationWord:
                isBookmarked ? "remove" : "save",
            accessibilityLabel:
                isBookmarked
                    ? "Remove bookmark"
                    : "Add bookmark",
            action: {
                audioManager.play(.buttonSoftPop)
                isBookmarked.toggle()
            }
        ) {
            Image(
                systemName:
                    isBookmarked
                        ? "bookmark.fill"
                        : "bookmark"
            )
            .font(.title2)
            .foregroundColor(
                DesignTokens.ColorToken.primaryBurgundy
            )
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive
            )
        )
    }
}




















