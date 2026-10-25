import SwiftUI
import UIKit

/// Shared Fruitfolio press-and-hold discoverability surface.
///
/// Founder-approved runtime alignment after Prompts 01–07:
/// - 0.50 second hold
/// - exactly one lowercase identification word
/// - deep Fruitfolio burgundy
/// - Chalkboard SE, matching the approved handwritten runtime typography
/// - normal tap and long press are mutually exclusive when using
///   `FruitfolioIconActionSurface`
struct FruitfolioHoldIdentifyModifier: ViewModifier {
    let word: String

    @State
    private var showing = false

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(Text(word))
            .overlay(alignment: .top) {
                if showing {
                    FruitfolioMicroLabel(word: word)
                        .offset(y: -34)
                        .transition(
                            .opacity.combined(
                                with: .scale(scale: 0.96)
                            )
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .onLongPressGesture(
                minimumDuration: 0.50,
                maximumDistance: 10
            ) {
                showBriefly()
            }
    }

    @MainActor
    private func showBriefly() {
        showing = true

        Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: 1_150_000_000
            )

            showing = false
        }
    }
}

/// Compatibility extension retained so earlier Prompt 06 code
/// continues to compile.
///
/// New icon-only controls should use `FruitfolioIconActionSurface`,
/// which owns both tap and hold recognition and therefore guarantees
/// that both actions cannot fire.
extension View {
    func fruitfolioHoldIdentify(
        _ word: String
    ) -> some View {
        modifier(
            FruitfolioHoldIdentifyModifier(
                word: word
            )
        )
    }
}

struct FruitfolioMicroLabel: View {
    let word: String

    var body: some View {
        Text(word.lowercased())
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 12,
                    relativeTo: .caption
                )
            )
            .fontWeight(.bold)
            .foregroundStyle(
                DesignTokens.ColorToken.primaryBurgundy
            )
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                DesignTokens.ColorToken.backgroundCream
                    .opacity(0.97),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        DesignTokens.ColorToken
                            .secondaryBurgundy
                            .opacity(0.18),
                        lineWidth: 0.75
                    )
            }
            .fixedSize(
                horizontal: true,
                vertical: true
            )
    }
}

/// One reusable owner for icon-only tap + hold behavior.
///
/// The exclusive gesture remains responsible for deciding whether the
/// interaction is a long press or a normal tap. A successful 0.50 second
/// hold shows the micro-label and does not also invoke the normal tap action.
///
/// A separate zero-distance drag gesture is used only for visual pressed-state
/// feedback. It never triggers the action or identification label.
///
/// The pressed-state animation intentionally mirrors `CutePopButtonStyle`:
/// - scale to 0.88
/// - move down 5 points
/// - rotate -1.2 degrees
/// - darken slightly
/// - spring back using response 0.20 / damping 0.38
struct FruitfolioIconActionSurface<Label: View>: View {
    let identificationWord: String
    let accessibilityLabel: String
    let isEnabled: Bool
    let action: () -> Void

    @ViewBuilder
    let label: () -> Label

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    @State
    private var showingIdentification = false

    @State
    private var isPressed = false

    init(
        identificationWord: String,
        accessibilityLabel: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.identificationWord = identificationWord
        self.accessibilityLabel = accessibilityLabel
        self.isEnabled = isEnabled
        self.action = action
        self.label = label
    }

    var body: some View {
        label()
            .frame(
                minWidth:
                    DesignTokens.Layout.minimumHitTarget,
                minHeight:
                    DesignTokens.Layout.minimumHitTarget
            )
            .contentShape(Rectangle())

            // MARK: CutePopButtonStyle-matched press animation

            .scaleEffect(
                motionPreferences.reduceMotionActive
                    ? 1.0
                    : (isPressed ? 0.88 : 1.0)
            )
            .offset(
                y: motionPreferences.reduceMotionActive
                    ? 0
                    : (isPressed ? 5 : 0)
            )
            .rotationEffect(
                .degrees(
                    motionPreferences.reduceMotionActive
                        ? 0
                        : (isPressed ? -1.2 : 0)
                )
            )
            .brightness(
                isPressed
                    ? -0.04
                    : 0
            )
            .opacity(
                isEnabled
                    ? 1
                    : 0.48
            )

            // MARK: Hold identification label

            .overlay(alignment: .top) {
                if showingIdentification {
                    FruitfolioMicroLabel(
                        word: identificationWord
                    )
                    .offset(y: -34)
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.96)
                        )
                    )
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }

            // MARK: Interaction

            .gesture(
                exclusiveTapOrHold
            )
            .simultaneousGesture(
                pressStateGesture
            )

            // MARK: Accessibility

            .accessibilityElement(
                children: .ignore
            )
            .accessibilityLabel(
                Text(accessibilityLabel)
            )
            .accessibilityAddTraits(
                .isButton
            )
            .accessibilityAction {
                guard isEnabled else {
                    return
                }

                action()
            }

            // MARK: Animation

            .animation(
                motionPreferences.reduceMotionActive
                    ? .easeOut(duration: 0.08)
                    : .spring(
                        response: 0.20,
                        dampingFraction: 0.38,
                        blendDuration: 0
                    ),
                value: isPressed
            )
            .animation(
                .easeOut(duration: 0.12),
                value: showingIdentification
            )
    }

    /// Long press gets first opportunity to recognize.
    ///
    /// If the interaction reaches 0.50 seconds, it identifies the
    /// icon and DOES NOT execute the normal action.
    ///
    /// A normal tap executes the action instead.
    private var exclusiveTapOrHold: some Gesture {
        LongPressGesture(
            minimumDuration: 0.50,
            maximumDistance: 10
        )
        .exclusively(
            before: TapGesture()
        )
        .onEnded { result in
            guard isEnabled else {
                return
            }

            switch result {

            case .first(let held):
                guard held else {
                    return
                }

                showIdentificationBriefly()

            case .second:
                action()
            }
        }
    }

    /// Visual feedback only.
    ///
    /// This gesture does NOT execute the button action and does NOT
    /// trigger the identification label. It exists solely to expose
    /// the same pressed-state animation used by `CutePopButtonStyle`.
    private var pressStateGesture: some Gesture {
        DragGesture(
            minimumDistance: 0
        )
        .onChanged { _ in
            guard isEnabled else {
                return
            }

            isPressed = true
        }
        .onEnded { _ in
            isPressed = false
        }
    }

    @MainActor
    private func showIdentificationBriefly() {
        showingIdentification = true

        Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: 1_150_000_000
            )

            showingIdentification = false
        }
    }
}

/// Retained for compatibility with prior diagnostics while reflecting
/// the actual founder-approved runtime font choice made during
/// Prompts 04–07.
enum FruitfolioMicroLabelFont {
    static var comicSansMSAvailable: Bool {
        UIFont(
            name: "Comic Sans MS",
            size: 12
        ) != nil
    }

    static var approvedRuntimeFontAvailable: Bool {
        UIFont(
            name: "Chalkboard SE",
            size: 12
        ) != nil
    }
}
