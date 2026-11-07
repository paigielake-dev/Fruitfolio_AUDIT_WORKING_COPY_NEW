import SwiftUI
import Foundation
import UIKit

@MainActor
struct Prompt21BodyBiologyView: View {
    var loader = Prompt21BodyBiologyLoader()
    var context: Prompt27AUserReproductiveContext = .unspecified
    var contextPolicy: Prompt27AContextPolicyResult = .init()

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var viewIsVisible = false
    private var canInteract: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
            && popupCoordinator.currentPopup == nil
    }

    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager

    @State private var loadState: LoadState = .loading
    @State private var input: Prompt21BodyBiologyInput = .neutral
    private var presentation: Prompt21BodyBiologyPresentation {
        Prompt21BodyBiologyEngine().presentation(for: input, contextPolicy: contextPolicy)
    }
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
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await load()
        }
        .onAppear { viewIsVisible = true }
        .onDisappear { viewIsVisible = false; settleDecorativeMotion() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { settleDecorativeMotion() }
        }
        .onChange(of: popupCoordinator.currentPopup != nil) { _, covered in
            if covered { settleDecorativeMotion() }
        }
        .onChange(of: contextPolicy) { _, _ in
            fimbriaeExpanded = false
            settleDecorativeMotion()
        }
        .onChange(of: motionPreferences.reduceMotionActive) { _, reduced in
            guard reduced else { return }
            settleDecorativeMotion()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            Image(Prompt21BodyBiologyAsset.sprout)
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            FruitfolioFixedText(source: "opening your biology page…", font: Prompt21Type.body, serious: true)
                .font(Prompt21Type.body)
                .foregroundStyle(Prompt21Palette.burgundy.opacity(0.70))
        }
        .frame(maxWidth: .infinity, minHeight: 430)
        .accessibilityElement(children: .combine)
    }

    private var fallbackView: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            FruitfolioScientificIllustration(imageName: Prompt21BodyBiologyAsset.ovary,
                accessibilityDescription: "watercolor educational illustration of an ovary, shown as a general biology reference", maximumWidth: 230)
                .frame(maxWidth: .infinity)

            FruitfolioFixedText(source: "your biology, in context", font: Prompt21Type.contextTitle, serious: true)
                .font(Prompt21Type.contextTitle)
                .foregroundStyle(Prompt21Palette.burgundy)

            FruitfolioTranslatedText(source: "as your cycle picture develops, this space can show the biology that may be most relevant.", font: Prompt21Type.body, serious: true)
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

            FruitfolioTranslatedText(source: "general biology reference — this illustration does not confirm ovulation or measure what is happening inside your body.",
                font: Prompt21Type.note, color: Prompt21Palette.burgundy.opacity(0.76), serious: true)

            VStack(alignment: .leading, spacing: 9) {
                FruitfolioFixedText(source: presentation.title, font: Prompt21Type.contextTitle, serious: true)
                    .font(Prompt21Type.contextTitle)
                    .foregroundStyle(Prompt21Palette.burgundy)
                    .accessibilityAddTraits(.isHeader)

                FruitfolioTranslatedText(source: presentation.bodyMarkup, font: Prompt21Type.body,
                    color: Prompt21Palette.burgundy, serious: true)
                    .font(Prompt21Type.body)
                    .foregroundStyle(Prompt21Palette.burgundy.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if presentation.state == .menstruation {
                FruitfolioTranslatedText(source: "the illustration separates structures for clarity — inside the body, these structures sit much more closely together.", font: Prompt21Type.note, serious: true)
                    .font(Prompt21Type.note)
                    .foregroundStyle(Prompt21Palette.burgundy.opacity(0.76))
                    .fixedSize(horizontal: false, vertical: true)
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

            FruitfolioFixedText(source: "what may be happening", font: Prompt21Type.title, serious: true)
                .font(Prompt21Type.title)
                .foregroundStyle(Prompt21Palette.burgundy)
                .accessibilityAddTraits(.isHeader)

            if let clarification = Prompt27AContextPresentationCopy.todayClarification(context: context, policy: contextPolicy) {
                FruitfolioTranslatedText(source: clarification, font: Prompt21Type.note, serious: true)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("bodyBiology.contextClarification")
            }

            FruitfolioTranslatedText(source: "educational view based on your current cycle context", font: Prompt21Type.subtitle, serious: true)
                .font(Prompt21Type.subtitle)
                .foregroundStyle(Prompt21Palette.burgundy.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var heroPlate: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .center) {
                ZStack {
                    FruitfolioScientificIllustration(imageName: presentation.heroAssetName,
                        accessibilityDescription: presentation.heroAccessibilityLabel, maximumWidth: 268)

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
                .overlay {
                    if presentation.permitsOocyteDrift,
                       let supportingAssetName = presentation.supportingAssetName {
                        GeometryReader { proxy in
                            let scale = min(proxy.size.width / 268, 1)
                            Image(supportingAssetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44 * scale, height: 44 * scale)
                                .position(x: proxy.size.width / 2 + (82 + oocyteOffset) * scale,
                                          y: proxy.size.height / 2 + 22 * scale)
                                .accessibilityLabel(presentation.supportingAccessibilityLabel
                                    ?? "watercolor educational illustration of a mature oocyte")
                        }
                        .allowsHitTesting(false)
                    }
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
        .allowsHitTesting(false)
    }

    private var blueberryNote: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(Prompt21BodyBiologyAsset.blueberry)
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .accessibilityHidden(true)

            FruitfolioTranslatedText(source: "this is an estimate, not a confirmation ✿", font: Prompt21Type.note, serious: true)
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
                guard canInteract else { return }
                audioManager.play(.buttonSoftPop)
                fimbriaeExpanded.toggle()
            } label: {
                Text("tiny detail: fimbriae")
                    .font(Prompt21Type.detailLabel)
                .foregroundStyle(Prompt21Palette.burgundy.opacity(0.80))
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(
                Prompt21SoftPressButtonStyle(
                    reduceMotionActive: motionPreferences.reduceMotionActive
                )
            )
            .accessibilityIdentifier("bodyBiology.fimbriaeDetail")
            .accessibilityLabel("Fimbriae detail")
            .accessibilityValue(fimbriaeExpanded ? "expanded" : "collapsed")
            .accessibilityHint("Shows or hides a small educational detail about the fimbriae")

            if fimbriaeExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    FruitfolioScientificIllustration(imageName: Prompt21BodyBiologyAsset.fimbriae,
                        accessibilityDescription: "watercolor educational illustration of the fimbriae beside the ovary and uterine tube",
                        maximumWidth: 112, maximumHeight: 140)

                    FruitfolioTranslatedText(source: "these finger-like structures help sweep the released oocyte toward the uterine tube.", font: Prompt21Type.note, serious: true)
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
            guard !Task.isCancelled, scenePhase == .active else { return }

            input = loadedInput
            loadState = .loaded

            if motionPreferences.reduceMotionActive || !canInteract {
                illustrationVisible = true
            } else {
                illustrationVisible = false
                withAnimation(.easeOut(duration: 0.28)) {
                    illustrationVisible = true
                }
            }

            await runOocyteDriftIfNeeded()
        } catch {
            guard !Task.isCancelled, scenePhase == .active else { return }
            input = .neutral
            loadState = .failed
            illustrationVisible = true
        }
    }

    private func settleDecorativeMotion() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { oocyteOffset = 0; illustrationVisible = true }
    }

    private func runOocyteDriftIfNeeded() async {
        guard canInteract, presentation.permitsOocyteDrift,
              !motionPreferences.reduceMotionActive,
              !oocyteDriftPlayed
        else {
            return
        }

        try? await Task.sleep(for: .milliseconds(320))
        guard !Task.isCancelled, canInteract, !motionPreferences.reduceMotionActive,
              presentation.permitsOocyteDrift else { return }

        oocyteDriftPlayed = true
        withAnimation(.easeInOut(duration: 0.72)) {
            oocyteOffset = 8
        }
    }
}

private struct Prompt21SoftPressButtonStyle: ButtonStyle {
    let reduceMotionActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(FruitfolioButtonPopEffect(isPressed: configuration.isPressed, reduceMotion: reduceMotionActive))
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

