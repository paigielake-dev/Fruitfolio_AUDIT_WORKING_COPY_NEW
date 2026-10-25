import SwiftUI
import Foundation

@MainActor
struct Prompt21BodyBiologyView: View {
    var loader = Prompt21BodyBiologyLoader()

    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager

    @State private var loadState: LoadState = .loading
    @State private var input: Prompt21BodyBiologyInput = .neutral
    @State private var presentation = Prompt21BodyBiologyEngine()
        .presentation(for: .neutral)
    @State private var fimbriaeExpanded = false
    @State private var illustrationVisible = false
    @State private var oocyteOffset: CGFloat = 0

    @SceneStorage("prompt21.oocyteDriftPlayed")
    private var oocyteDriftPlayed = false

    private enum LoadState {
        case loading
        case loaded
        case failed
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                loadingView

            case .loaded:
                content

            case .failed:
                fallbackView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            await load()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            Image(Prompt21BodyBiologyAsset.sprout)
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            Text("opening your biology page…")
                .font(Prompt21Type.body)
                .foregroundStyle(Prompt21Palette.burgundy.opacity(0.70))
        }
        .frame(maxWidth: .infinity, minHeight: 430)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading body biology")
    }

    private var fallbackView: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            Image(Prompt21BodyBiologyAsset.ovary)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 230)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(
                    "watercolor educational illustration of an ovary, shown as a general biology reference"
                )

            Text("your biology, in context")
                .font(Prompt21Type.contextTitle)
                .foregroundStyle(Prompt21Palette.burgundy)

            Text(
                "as your cycle picture develops, this space can show the biology that may be most relevant."
            )
            .font(Prompt21Type.body)
            .foregroundStyle(Prompt21Palette.burgundy.opacity(0.82))
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            heroPlate
                .opacity(illustrationVisible ? 1 : 0)
                .scaleEffect(
                    illustrationVisible || motionPreferences.reduceMotionActive
                        ? 1
                        : 0.985
                )

            VStack(alignment: .leading, spacing: 9) {
                Text(presentation.title)
                    .font(Prompt21Type.contextTitle)
                    .foregroundStyle(Prompt21Palette.burgundy)
                    .accessibilityAddTraits(.isHeader)

                Text(presentation.body)
                    .font(Prompt21Type.body)
                    .foregroundStyle(Prompt21Palette.burgundy.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if presentation.state == .menstruation {
                Text("the illustration separates structures for clarity — inside the body, these structures sit much more closely together.")
                    .font(Prompt21Type.note)
                    .foregroundStyle(Prompt21Palette.burgundy.opacity(0.76))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Educational illustration note. The illustration separates structures for clarity. Inside the body, these structures sit much more closely together.")
            }

            if presentation.showsBlueberryUncertainty {
                blueberryNote
            }

            if presentation.permitsFimbriaeDetail {
                fimbriaeSection
            }

            if presentation.showsPeachDayOne {
                peachDayOneNote
            }
        }
        .frame(maxWidth: 620, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
        .animation(
            motionPreferences.reduceMotionActive
                ? nil
                : .easeOut(duration: 0.24),
            value: fimbriaeExpanded
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image("decor_flowers")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82)
                    .rotationEffect(.degrees(-4))
                    .opacity(0.90)
                    .offset(x: -8)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                Spacer()
            }
            .frame(height: 54)

            Text("what may be happening")
                .font(Prompt21Type.title)
                .foregroundStyle(Prompt21Palette.burgundy)
                .accessibilityAddTraits(.isHeader)

            Text("educational view based on your current cycle context")
                .font(Prompt21Type.subtitle)
                .foregroundStyle(Prompt21Palette.burgundy.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var heroPlate: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .center) {
                ZStack {
                    Image(presentation.heroAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 268)
                        .accessibilityLabel(presentation.heroAccessibilityLabel)

                    if presentation.state == .menstruation {
                        GeometryReader { proxy in
                            let width = proxy.size.width
                            let height = proxy.size.height

                            Ellipse()
                                .stroke(Color(hex: 0x800000).opacity(0.72), lineWidth: 1.2)
                                .frame(width: width * 0.28, height: height * 0.24)
                                .position(x: width * 0.50, y: height * 0.52)

                            Path { path in
                                let start = CGPoint(x: width * 0.77, y: height * 0.35)
                                let end = CGPoint(x: width * 0.61, y: height * 0.46)
                                path.move(to: start)
                                path.addLine(to: end)
                                path.move(to: end)
                                path.addLine(to: CGPoint(x: end.x + width * 0.035, y: end.y - height * 0.008))
                                path.move(to: end)
                                path.addLine(to: CGPoint(x: end.x + width * 0.018, y: end.y - height * 0.035))
                            }
                            .stroke(Color(hex: 0x800000).opacity(0.76), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                        }
                        .frame(maxWidth: 268)
                        .aspectRatio(1, contentMode: .fit)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: 268)

                if presentation.permitsOocyteDrift,
                   let supportingAssetName = presentation.supportingAssetName {
                    Image(supportingAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .offset(x: 82 + oocyteOffset, y: 22)
                        .accessibilityLabel(
                            presentation.supportingAccessibilityLabel
                                ?? "watercolor educational illustration of a mature oocyte"
                        )
                }
            }
            .frame(maxWidth: .infinity)

            if presentation.state == .menstruation,
               let supportingAssetName = presentation.supportingAssetName {
                Image(supportingAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 150)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(
                        presentation.supportingAccessibilityLabel
                            ?? "watercolor educational illustration of the uterine lining during menstruation"
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var blueberryNote: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(Prompt21BodyBiologyAsset.blueberry)
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .accessibilityHidden(true)

            Text("this is an estimate, not a confirmation ✿")
                .font(Prompt21Type.note)
                .foregroundStyle(Prompt21Palette.burgundy.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Blueberry says, this is an estimate, not a confirmation")
    }

    private var fimbriaeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                audioManager.play(.buttonSoftPop)
                fimbriaeExpanded.toggle()
            } label: {
                Text("tiny detail: fimbriae")
                    .font(Prompt21Type.detailLabel)
                .foregroundStyle(Prompt21Palette.burgundy.opacity(0.80))
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(
                Prompt21SoftPressButtonStyle(
                    reduceMotionActive: motionPreferences.reduceMotionActive
                )
            )
            .accessibilityLabel("Fimbriae detail")
            .accessibilityValue(fimbriaeExpanded ? "expanded" : "collapsed")
            .accessibilityHint("Shows or hides a small educational detail about the fimbriae")

            if fimbriaeExpanded {
                HStack(alignment: .center, spacing: 16) {
                    Image(Prompt21BodyBiologyAsset.fimbriae)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112)
                        .accessibilityLabel(
                            "watercolor educational illustration of the fimbriae beside the ovary and uterine tube"
                        )

                    Text(
                        "these finger-like structures help sweep the released oocyte toward the uterine tube."
                    )
                    .font(Prompt21Type.note)
                    .foregroundStyle(Prompt21Palette.burgundy.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 6)
                .transition(.opacity)
            }
        }
    }

    private var peachDayOneNote: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(Prompt21BodyBiologyAsset.peach)
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .accessibilityHidden(true)

            Text("new cycle, day 1")
                .font(Prompt21Type.note)
                .foregroundStyle(Prompt21Palette.burgundy.opacity(0.82))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Peach says, new cycle, day 1")
    }

    private func load() async {
        do {
            let loadedInput = try await loader.load(now: Date())
            guard !Task.isCancelled else { return }

            input = loadedInput
            presentation = Prompt21BodyBiologyEngine()
                .presentation(for: loadedInput)
            loadState = .loaded

            if motionPreferences.reduceMotionActive {
                illustrationVisible = true
            } else {
                illustrationVisible = false
                withAnimation(.easeOut(duration: 0.28)) {
                    illustrationVisible = true
                }
            }

            await runOocyteDriftIfNeeded()
        } catch {
            guard !Task.isCancelled else { return }
            input = .neutral
            presentation = Prompt21BodyBiologyEngine()
                .presentation(for: .neutral)
            loadState = .failed
            illustrationVisible = true
        }
    }

    private func runOocyteDriftIfNeeded() async {
        guard presentation.permitsOocyteDrift,
              !motionPreferences.reduceMotionActive,
              !oocyteDriftPlayed
        else {
            return
        }

        oocyteDriftPlayed = true

        try? await Task.sleep(for: .milliseconds(320))
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.72)) {
            oocyteOffset = 8
        }
    }
}

private struct Prompt21SoftPressButtonStyle: ButtonStyle {
    let reduceMotionActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed && !reduceMotionActive
                    ? 0.965
                    : 1
            )
            .offset(
                y: configuration.isPressed && !reduceMotionActive
                    ? 1.5
                    : 0
            )
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(
                reduceMotionActive
                    ? nil
                    : .spring(
                        response: 0.22,
                        dampingFraction: 0.70,
                        blendDuration: 0
                    ),
                value: configuration.isPressed
            )
    }
}

private enum Prompt21Palette {
    static let burgundy = Color(
        red: 128.0 / 255.0,
        green: 0,
        blue: 0
    )
}

private enum Prompt21Type {
    static let title = Font.custom(
        "Chalkboard SE",
        size: 28,
        relativeTo: .title
    )
    .weight(.bold)

    static let subtitle = Font.custom(
        "Chalkboard SE",
        size: 12.5,
        relativeTo: .subheadline
    )

    static let contextTitle = Font.custom(
        "Chalkboard SE",
        size: 20,
        relativeTo: .title3
    )
    .weight(.semibold)

    static let body = Font.custom(
        "Chalkboard SE",
        size: 14,
        relativeTo: .body
    )

    static let note = Font.custom(
        "Chalkboard SE",
        size: 12.5,
        relativeTo: .subheadline
    )

    static let detailLabel = Font.custom(
        "Chalkboard SE",
        size: 12,
        relativeTo: .caption
    )
}

