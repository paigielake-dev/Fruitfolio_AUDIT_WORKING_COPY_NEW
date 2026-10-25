import SwiftUI

@MainActor
struct Prompt25FertilizationView: View {
    private let onBack: () -> Void
    private let onSources: (Prompt25FertilizationStage) -> Void
    private let onAsk: (Prompt25FertilizationStage) -> Void
    private let onSave: (Prompt25FertilizationStage) -> Void
    private let onRelatedTopic: (Prompt25RelatedTopic) -> Void
    private let onPageSound: () -> Void

    @StateObject private var viewModel: Prompt25FertilizationViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var dragOffset: CGFloat = 0
    @State private var swipeCueOffset: CGFloat = 0
    @State private var hasShownSwipeCue = false
    @AccessibilityFocusState private var stageHeadingFocused: Bool

    init(
        initialStage: Prompt25FertilizationStageID = .oocyte,
        contentProvider: any Prompt25FertilizationContentProviding =
            Prompt25UnavailableContentProvider(),
        onBack: @escaping () -> Void = {},
        onSources: @escaping (Prompt25FertilizationStage) -> Void = { _ in },
        onAsk: @escaping (Prompt25FertilizationStage) -> Void = { _ in },
        onSave: @escaping (Prompt25FertilizationStage) -> Void = { _ in },
        onRelatedTopic: @escaping (Prompt25RelatedTopic) -> Void = { _ in },
        onPageSound: @escaping () -> Void = {}
    ) {
        self.onBack = onBack
        self.onSources = onSources
        self.onAsk = onAsk
        self.onSave = onSave
        self.onRelatedTopic = onRelatedTopic
        self.onPageSound = onPageSound
        _viewModel = StateObject(
            wrappedValue: Prompt25FertilizationViewModel(
                initialStage: initialStage,
                contentProvider: contentProvider
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Prompt25Palette.paper
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        topBar
                            .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                            .padding(.top, 10)

                        chapterIntro
                            .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                            .padding(.top, 12)

                        stagePlate(maxWidth: contentWidth(for: geometry.size.width))
                            .padding(.top, 18)

                        navigationArea
                            .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                            .padding(.top, 18)
                            .padding(.bottom, 32)
                    }
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .task(id: viewModel.stageID) {
            await viewModel.loadContent()
            stageHeadingFocused = true
            await showSwipeCueIfNeeded()
        }
        .accessibilityIdentifier("prompt25.fertilization")
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image("control_previous")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .accessibilityHidden(true)

                    Text("back")
                }
                .font(prompt25Font(13, relativeTo: .subheadline))
                .foregroundStyle(Prompt25Palette.burgundy)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(
                Prompt25SoftPressButtonStyle(reduceMotion: reduceMotion)
            )
            .accessibilityLabel("Back")

            Spacer(minLength: 16)

            Text("fertilization")
                .font(prompt25Font(19, relativeTo: .headline))
                .fontWeight(.bold)
                .foregroundStyle(Prompt25Palette.burgundy)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var chapterIntro: some View {
        Text(
            "explore the general biological stages from an oocyte through early preimplantation development."
        )
        .font(prompt25Font(13, relativeTo: .body))
        .foregroundStyle(Prompt25Palette.burgundy.opacity(0.72))
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 520, alignment: .leading)
    }

    private func stagePlate(maxWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            stageHeader
            primaryIllustration(maxWidth: maxWidth)
            educationalCopy
            secondaryEducation
            progressMarks
        }
        .frame(maxWidth: maxWidth)
        .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 18 : 24)
        .padding(.vertical, 20)
        .offset(x: reduceMotion ? 0 : dragOffset * 0.16)
        .contentShape(Rectangle())
        .gesture(stageSwipeGesture)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.16),
            value: dragOffset
        )
    }

    private var stageHeader: some View {
        VStack(spacing: 6) {
            Text(viewModel.stage.indicatorText)
                .font(prompt25Font(11, relativeTo: .caption))
                .fontWeight(.semibold)
                .tracking(0.7)
                .foregroundStyle(Prompt25Palette.burgundy.opacity(0.56))

            Text(viewModel.stage.title)
                .font(prompt25Font(27, relativeTo: .title2))
                .fontWeight(.bold)
                .foregroundStyle(Prompt25Palette.burgundy)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($stageHeadingFocused)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Stage \(viewModel.stage.order) of 6. \(viewModel.stage.title)."
        )
    }

    private func primaryIllustration(maxWidth: CGFloat) -> some View {
        let artWidth =
            dynamicTypeSize.isAccessibilitySize
                ? min(maxWidth * 0.72, 280)
                : min(maxWidth * 0.58, 310)

        return Image(viewModel.stage.primaryAssetID.imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: artWidth)
            .frame(minHeight: 190)
            .accessibilityLabel(viewModel.stage.accessibilityLabel)
    }

    @ViewBuilder
    private var educationalCopy: some View {
        switch viewModel.contentState {
        case .idle, .loading:
            Prompt25LoadingCopy()
        case .loaded:
            Text(viewModel.content.shortText)
                .font(prompt25Font(14, relativeTo: .body))
                .foregroundStyle(Prompt25Palette.burgundy.opacity(0.86))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 560, alignment: .leading)
        case .unavailable:
            Text("approved educational content isn’t available right now.")
                .font(prompt25Font(13, relativeTo: .body))
                .foregroundStyle(Prompt25Palette.burgundy.opacity(0.68))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 520)
        }
    }

    @ViewBuilder
    private var secondaryEducation: some View {
        VStack(spacing: 12) {
            if viewModel.contentState == .loaded,
               !viewModel.content.expandedSections.isEmpty {
                Button {
                    withAnimation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 0.24)
                    ) {
                        viewModel.isExpanded.toggle()
                    }
                } label: {
                    Text(
                        viewModel.isExpanded
                            ? "show less"
                            : "learn a little more"
                    )
                    .font(prompt25Font(13, relativeTo: .subheadline))
                    .fontWeight(.semibold)
                    .foregroundStyle(Prompt25Palette.burgundy)
                    .frame(minHeight: 44)
                }
                .buttonStyle(
                    Prompt25SoftPressButtonStyle(
                        reduceMotion: reduceMotion
                    )
                )
            }

            if viewModel.isExpanded {
                expandedContent
                    .transition(.opacity)
            }

            HStack(spacing: 18) {
                Button {
                    onSources(viewModel.stage)
                } label: {
                    Text(
                        viewModel.content.sourceCount > 0
                            ? "sources · \(viewModel.content.sourceCount)"
                            : "sources"
                    )
                }

                Button {
                    onAsk(viewModel.stage)
                } label: {
                    Text("ask")
                }

                Button {
                    onSave(viewModel.stage)
                } label: {
                    Text("save")
                }
            }
            .font(prompt25Font(12, relativeTo: .footnote))
            .foregroundStyle(Prompt25Palette.burgundy.opacity(0.78))
            .buttonStyle(
                Prompt25SoftPressButtonStyle(
                    reduceMotion: reduceMotion
                )
            )

            if viewModel.stageID == .blastocyst {
                blastocystEnding
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(viewModel.content.expandedSections) { section in
                VStack(alignment: .leading, spacing: 5) {
                    Text(section.heading)
                        .font(prompt25Font(13, relativeTo: .headline))
                        .fontWeight(.semibold)
                        .foregroundStyle(Prompt25Palette.burgundy)

                    Text(section.body)
                        .font(prompt25Font(13, relativeTo: .body))
                        .foregroundStyle(
                            Prompt25Palette.burgundy.opacity(0.80)
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            let learnMoreArt = viewModel.stage.auxiliaryArt.filter {
                $0.role == .learnMore
            }

            if !learnMoreArt.isEmpty {
                HStack(alignment: .top, spacing: 18) {
                    ForEach(learnMoreArt) { item in
                        Image(item.assetID.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 120, maxHeight: 120)
                            .accessibilityLabel(
                                item.accessibilityLabel
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: 560, alignment: .leading)
    }

    private var blastocystEnding: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 0.24)
                ) {
                    viewModel.showsRelatedTopics.toggle()
                }
            } label: {
                Text(
                    viewModel.showsRelatedTopics
                        ? "hide related topics"
                        : "related topics"
                )
                .font(prompt25Font(12, relativeTo: .footnote))
                .foregroundStyle(
                    Prompt25Palette.burgundy.opacity(0.74)
                )
                .frame(minHeight: 44)
            }
            .buttonStyle(
                Prompt25SoftPressButtonStyle(
                    reduceMotion: reduceMotion
                )
            )

            if viewModel.showsRelatedTopics {
                relatedTopics
                    .transition(.opacity)
            }
        }
    }

    private var relatedTopics: some View {
        VStack(spacing: 10) {
            ForEach(Prompt25RelatedTopic.allCases) { topic in
                Button {
                    onRelatedTopic(topic)
                } label: {
                    HStack(spacing: 10) {
                        if topic == .implantation,
                           let art = viewModel.stage.auxiliaryArt.first(
                            where: {
                                $0.role == .relatedTopic
                                    && $0.assetID
                                        == .implantationUterus
                            }
                           ) {
                            Image(art.assetID.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 54, height: 54)
                                .accessibilityHidden(true)
                        }

                        Text(topic.title)
                            .font(
                                prompt25Font(
                                    12,
                                    relativeTo: .subheadline
                                )
                            )
                            .foregroundStyle(
                                Prompt25Palette.burgundy
                            )

                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(
                    Prompt25SoftPressButtonStyle(
                        reduceMotion: reduceMotion
                    )
                )
                .accessibilityLabel(topic.title)
            }
        }
        .frame(maxWidth: 420)
    }

    private var progressMarks: some View {
        HStack(spacing: 9) {
            ForEach(Prompt25FertilizationSequence.stages) { stage in
                Circle()
                    .fill(
                        stage.id == viewModel.stageID
                            ? Prompt25Palette.burgundy.opacity(0.78)
                            : Prompt25Palette.burgundy.opacity(0.18)
                    )
                    .frame(
                        width: stage.id == viewModel.stageID ? 7 : 6,
                        height: stage.id == viewModel.stageID ? 7 : 6
                    )
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Page \(viewModel.stage.order) of 6"
        )
        .offset(x: swipeCueOffset)
    }

    private var navigationArea: some View {
        HStack(spacing: 14) {
            if viewModel.canGoPrevious {
                Prompt25NavigationButton(
                    title: "previous",
                    imageName: "control_previous",
                    imageFirst: true,
                    reduceMotion: reduceMotion
                ) {
                    navigatePrevious()
                }
            } else {
                Spacer()
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 10)

            if viewModel.canGoNext {
                Prompt25NavigationButton(
                    title: "next",
                    imageName: "control_next",
                    imageFirst: false,
                    reduceMotion: reduceMotion
                ) {
                    navigateNext()
                }
            } else {
                Text("end of chapter")
                    .font(prompt25Font(12, relativeTo: .footnote))
                    .foregroundStyle(
                        Prompt25Palette.burgundy.opacity(0.56)
                    )
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    private var stageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard !viewModel.isTransitioning else { return }
                let horizontal = value.translation.width
                let vertical = value.translation.height

                guard abs(horizontal) > abs(vertical) else { return }
                dragOffset = max(-70, min(70, horizontal))
            }
            .onEnded { value in
                defer {
                    withAnimation(
                        reduceMotion
                            ? nil
                            : .easeOut(duration: 0.16)
                    ) {
                        dragOffset = 0
                    }
                }

                guard !viewModel.isTransitioning else { return }

                let horizontal = value.translation.width
                let vertical = value.translation.height
                let projected = value.predictedEndTranslation.width

                guard abs(horizontal) > abs(vertical) else { return }

                let threshold: CGFloat = 52
                let committedDistance =
                    abs(projected) > abs(horizontal)
                        ? projected
                        : horizontal

                if committedDistance <= -threshold {
                    navigateNext()
                } else if committedDistance >= threshold {
                    navigatePrevious()
                }
            }
    }

    private func navigatePrevious() {
        guard viewModel.canGoPrevious else { return }
        onPageSound()
        viewModel.previous(reduceMotion: reduceMotion)
    }

    private func navigateNext() {
        guard viewModel.canGoNext else { return }
        onPageSound()
        viewModel.next(reduceMotion: reduceMotion)
    }

    private func showSwipeCueIfNeeded() async {
        guard !hasShownSwipeCue,
              viewModel.stageID == .oocyte,
              !reduceMotion
        else {
            return
        }

        hasShownSwipeCue = true

        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.28)) {
            swipeCueOffset = 7
        }

        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.28)) {
            swipeCueOffset = 0
        }
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        if width < 360 { return 16 }
        if width < 700 { return 22 }
        return 34
    }

    private func contentWidth(for width: CGFloat) -> CGFloat {
        if width < 700 {
            return max(300, width - horizontalPadding(for: width) * 2)
        }
        if width < 1100 {
            return min(680, width - 90)
        }
        return 760
    }

    private func prompt25Font(
        _ size: CGFloat,
        relativeTo style: Font.TextStyle
    ) -> Font {
        Font.custom(
            "Chalkboard SE",
            size: size,
            relativeTo: style
        )
    }
}

private struct Prompt25NavigationButton: View {
    let title: String
    let imageName: String
    let imageFirst: Bool
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if imageFirst {
                    icon
                }

                Text(title)
                    .font(
                        Font.custom(
                            "Chalkboard SE",
                            size: 13,
                            relativeTo: .subheadline
                        )
                    )
                    .foregroundStyle(Prompt25Palette.burgundy)

                if !imageFirst {
                    icon
                }
            }
            .frame(minWidth: 92, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(
            Prompt25SoftPressButtonStyle(
                reduceMotion: reduceMotion
            )
        )
        .accessibilityLabel(title)
    }

    private var icon: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
    }
}

private struct Prompt25LoadingCopy: View {
    var body: some View {
        VStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Prompt25Palette.burgundy.opacity(0.09))
                .frame(height: 9)

            RoundedRectangle(cornerRadius: 4)
                .fill(Prompt25Palette.burgundy.opacity(0.06))
                .frame(maxWidth: 310)
                .frame(height: 9)
        }
        .frame(maxWidth: 440)
        .accessibilityLabel("Loading educational content")
    }
}

private struct Prompt25SoftPressButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                reduceMotion
                    ? 1
                    : (configuration.isPressed ? 0.965 : 1)
            )
            .offset(
                y:
                    reduceMotion
                        ? 0
                        : (configuration.isPressed ? 1.5 : 0)
            )
            .rotationEffect(
                .degrees(
                    reduceMotion
                        ? 0
                        : (configuration.isPressed ? -0.25 : 0)
                )
            )
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(
                reduceMotion
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

private enum Prompt25Palette {
    static let burgundy = Color(
        red: 128.0 / 255.0,
        green: 0,
        blue: 0
    )

    static let paper = Color(
        red: 0.988,
        green: 0.962,
        blue: 0.908
    )
}
