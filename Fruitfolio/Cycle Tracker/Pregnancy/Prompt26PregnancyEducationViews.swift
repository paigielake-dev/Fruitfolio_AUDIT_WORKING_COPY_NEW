#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct Prompt26PregnancyEducationRootView: View {
    private let provider: any Prompt26PregnancyResearchProviding
    private let actions: Prompt26PregnancyEducationActions
    private let entryContext: Prompt26PregnancyEntryContext

    init(
        provider: (any Prompt26PregnancyResearchProviding)? = nil,
        actions: Prompt26PregnancyEducationActions? = nil,
        entryContext: Prompt26PregnancyEntryContext = .intentionalEncyclopediaOpen
    ) {
        self.provider = provider ?? Prompt26UnavailableResearchProvider()
        self.actions = actions ?? Prompt26PregnancyEducationActions()
        self.entryContext = entryContext
    }

    var body: some View {
        Prompt26PregnancyLandingView(
            provider: provider,
            actions: actions,
            entryContext: entryContext
        )
        .tint(Prompt26Palette.burgundy)
    }
}

/// Use this only when launching Phase 26 outside Fruitfolio's existing NavigationStack,
/// such as an isolated development harness or preview. Production integration should
/// normally push `Prompt26PregnancyEducationRootView` through the established
/// Encyclopedia navigation architecture from Prompts 01–25.
struct Prompt26PregnancyEducationStandaloneView: View {
    private let provider: any Prompt26PregnancyResearchProviding
    private let actions: Prompt26PregnancyEducationActions

    init(
        provider: (any Prompt26PregnancyResearchProviding)? = nil,
        actions: Prompt26PregnancyEducationActions? = nil
    ) {
        self.provider = provider ?? Prompt26UnavailableResearchProvider()
        self.actions = actions ?? Prompt26PregnancyEducationActions()
    }

    var body: some View {
        NavigationStack {
            Prompt26PregnancyEducationRootView(provider: provider, actions: actions)
        }
    }
}

private struct Prompt26PregnancyLandingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    let provider: any Prompt26PregnancyResearchProviding
    let actions: Prompt26PregnancyEducationActions
    let entryContext: Prompt26PregnancyEntryContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    FruitfolioFixedText(source: "pregnancy", font: .custom("Chalkboard SE", size: 30, relativeTo: .largeTitle).weight(.bold), color: Prompt26Palette.burgundy, serious: true)
                    FruitfolioFixedText(source: "A research-based guide to pregnancy biology, testing, development, prenatal care concepts, and the structures that support pregnancy.", font: .body, color: Prompt26Palette.burgundy.opacity(0.82), serious: true)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !Prompt26PregnancyArtworkGate.mayDisplayPregnancySpecificArtwork(in: entryContext) {
                    Prompt26EducationBoundaryNotice()
                } else {
                    VStack(spacing: 14) {
                        ForEach(Prompt26PregnancyEducationCatalog.topics) { topic in
                            NavigationLink(value: topic.id) {
                                Prompt26TopicCard(topic: topic)
                            }
                            .buttonStyle(Prompt26SoftPressButtonStyle())
                            .accessibilityIdentifier("pregnancy.topic." + topic.id.rawValue)
                            .disabled(scenePhase != .active || popupCoordinator.currentPopup != nil)
                        }
                    }
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.vertical, 28)
        }
        .background(Prompt26Palette.paper.ignoresSafeArea())
        .navigationTitle("Pregnancy")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Prompt26PregnancyTopicID.self) { id in
            Prompt26PregnancyTopicView(
                topic: Prompt26PregnancyEducationCatalog.topic(id),
                provider: provider,
                actions: actions
            )
        }
    }
}

private struct Prompt26TopicCard: View {
    let topic: Prompt26PregnancyEducationTopic

    var body: some View {
        HStack(spacing: 16) {
            Image(topic.heroAsset.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                FruitfolioFixedText(source: topic.title, font: .custom("Chalkboard SE", size: 17, relativeTo: .headline).weight(.bold), color: Prompt26Palette.burgundy, serious: true)
                FruitfolioFixedText(source: topic.subtitle, font: .custom("Chalkboard SE", size: 13, relativeTo: .subheadline), color: Prompt26Palette.burgundy.opacity(0.75), serious: true)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            Image("control_next")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .opacity(0.72)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(
            Prompt26Palette.card.opacity(0.54),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Prompt26Palette.burgundy.opacity(0.08), lineWidth: 0.8)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .modifier(FruitfolioFixedAccessibilityLabel(source: "\(topic.title). \(topic.subtitle)"))
        .modifier(FruitfolioFixedAccessibilityHint(source: "Opens educational reference"))
    }
}

private struct Prompt26PregnancyTopicView: View {
    @StateObject private var model: Prompt26PregnancyEducationViewModel
    @State private var isExpanded = false
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewIsVisible = false
    private var reduceMotion: Bool { motionPreferences.reduceMotionActive }
    private var canInteract: Bool {
        viewIsVisible && scenePhase == .active && popupCoordinator.currentPopup == nil
            && UIApplication.shared.applicationState == .active
    }

    private let actions: Prompt26PregnancyEducationActions
    private let modelProvider: any Prompt26PregnancyResearchProviding

    init(
        topic: Prompt26PregnancyEducationTopic,
        provider: any Prompt26PregnancyResearchProviding,
        actions: Prompt26PregnancyEducationActions
    ) {
        _model = StateObject(wrappedValue: Prompt26PregnancyEducationViewModel(topic: topic, provider: provider))
        self.modelProvider = provider
        self.actions = actions
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 7) {
                    FruitfolioFixedText(source: model.topic.title, font: .custom("Chalkboard SE", size: 30, relativeTo: .largeTitle).weight(.bold), color: Prompt26Palette.burgundy, serious: true)
                    FruitfolioFixedText(source: model.topic.subtitle, font: .body, color: Prompt26Palette.burgundy.opacity(0.78), serious: true)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if model.topic.id == .fetalDevelopment {
                    Prompt26FetalReferenceSection(provider: modelProvider, actions: actions, presentationActive: canInteract)
                } else {
                    Prompt26HeroIllustration(topic: model.topic)
                }

                Prompt26ContentBody(
                    state: model.state,
                    isExpanded: Binding(get: { isExpanded }, set: { if canInteract { isExpanded = $0 } }),
                    retry: { guard canInteract else { return }; model.retry() }
                )

                if model.topic.id == .earlyDevelopment {
                    Button {
                        guard canInteract else { return }
                        actions.openFertilizationEducation()
                    } label: {
                        FruitfolioFixedText(source: "open fertilization education", font: .custom("Chalkboard SE", size: 13, relativeTo: .subheadline).bold(), color: Prompt26Palette.burgundy, serious: true)
                    }
                    .buttonStyle(Prompt26PaperButtonStyle())
                }

                Prompt26RelatedTopics(topic: model.topic)

                Prompt26ActionRow(
                    topic: model.topic,
                    content: model.loadedContent,
                    actions: actions,
                    interactionAllowed: { canInteract }
                )
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.vertical, 28)
        }
        .background(Prompt26Palette.paper.ignoresSafeArea())
        .navigationTitle(model.topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("pregnancy.topicPage." + model.topic.id.rawValue)
        .disabled(!canInteract)
        .onAppear { viewIsVisible = true }
        .onDisappear { viewIsVisible = false; model.suspendPresentation() }
        .task(id: canInteract) {
            guard canInteract else { model.suspendPresentation(); return }
            if let request = model.loadIfNeeded() { await request.value }
        }
        .onChange(of: canInteract) { _, active in
            if !active { model.suspendPresentation() }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: isExpanded)
    }
}

private struct Prompt26HeroIllustration: View {
    let topic: Prompt26PregnancyEducationTopic

    var body: some View {
        Prompt26CanonicalImage(
            asset: topic.heroAsset,
            altText: topic.altText,
            maxHeight: 320
        )
        .padding(.vertical, 8)
    }
}

private struct Prompt26ContentBody: View {
    let state: Prompt26PregnancyEducationViewModel.LoadState
    @Binding var isExpanded: Bool
    let retry: () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            HStack(spacing: 10) {
                ProgressView()
                FruitfolioFixedText(source: "opening approved research…", font: .subheadline, color: Prompt26Palette.burgundy.opacity(0.74), serious: true)
            }
            .accessibilityElement(children: .combine)

        case .unavailable:
            VStack(alignment: .leading, spacing: 12) {
                FruitfolioFixedText(source: "approved research is unavailable right now", font: .custom("Chalkboard SE", size: 17, relativeTo: .headline).weight(.bold), color: Prompt26Palette.burgundy, serious: true)
                FruitfolioFixedText(source: "Fruitfolio won’t fill pregnancy medicine from unsupported model knowledge. Try again when the Research Library is available.", protectedLiterals: ["Fruitfolio"], font: .body, color: Prompt26Palette.burgundy.opacity(0.76), serious: true)
                Button(action: retry) {
                    FruitfolioFixedText(source: "try again", font: .custom("Chalkboard SE", size: 13, relativeTo: .subheadline).bold(), color: Prompt26Palette.burgundy, serious: true)
                }
                    .buttonStyle(Prompt26PaperButtonStyle())
            }
            .padding(16)
            .background(Prompt26Palette.card.opacity(0.64), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        case let .loaded(content):
            VStack(alignment: .leading, spacing: 16) {
                FruitfolioTranslatedText(source: content.summary, protectedLiterals: content.sourceIDs, font: .body, color: Prompt26Palette.burgundy, serious: true)
                    .font(.body)
                    .foregroundStyle(Prompt26Palette.burgundy)
                    .fixedSize(horizontal: false, vertical: true)

                if !content.sections.isEmpty {
                    Button {
                        isExpanded.toggle()
                    } label: {
                        FruitfolioFixedText(source: isExpanded ? "show less" : "learn more", font: .custom("Chalkboard SE", size: 13, relativeTo: .subheadline).bold(), color: Prompt26Palette.burgundy, serious: true)
                    }
                    .buttonStyle(Prompt26PaperButtonStyle())

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(content.sections) { section in
                                VStack(alignment: .leading, spacing: 7) {
                                    FruitfolioFixedText(source: section.heading, font: .headline, color: Prompt26Palette.burgundy, serious: true)
                                    FruitfolioTranslatedText(source: section.body, protectedLiterals: section.sourceIDs, font: .body, color: Prompt26Palette.burgundy.opacity(0.84), serious: true)
                                        .font(.body)
                                        .foregroundStyle(Prompt26Palette.burgundy.opacity(0.84))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
    }
}

private struct Prompt26FetalReferenceSection: View {
    @EnvironmentObject private var settings: SettingsStore
    // Native Picker items need plain titles resolved by the visible parent.
    @StateObject private var reference1 = FruitfolioControlTranslationState()
    @StateObject private var reference2 = FruitfolioControlTranslationState()
    @StateObject private var reference3 = FruitfolioControlTranslationState()
    @StateObject private var reference4 = FruitfolioControlTranslationState()
    private var referenceStates: [FruitfolioControlTranslationState] {
        [reference1, reference2, reference3, reference4]
    }
    private func referenceKey(_ period: Prompt26DevelopmentReferencePeriod) -> FruitfolioControlTranslationState.Key {
        .init(source: period.displayRange, language: settings.language)
    }
    private func referenceDisplay(_ period: Prompt26DevelopmentReferencePeriod) -> FruitfolioControlTranslationState.Presentation {
        guard let index = Prompt26PregnancyEducationCatalog.fetalReferencePeriods.firstIndex(where: { $0.id == period.id }),
              index < referenceStates.count else {
            return .init(text: period.displayRange, status: .unavailable)
        }
        return referenceStates[index].presentation(for: referenceKey(period))
    }
    private var referenceCaption: String? {
        let statuses = Prompt26PregnancyEducationCatalog.fetalReferencePeriods.map { referenceDisplay($0).status }
        if statuses.contains(.unavailable) { return "original text — translation unavailable" }
        if statuses.contains(.preparing) { return "original text" }
        if statuses.contains(.machine) { return "local machine translation" }
        return nil
    }
    let provider: any Prompt26PregnancyResearchProviding
    let actions: Prompt26PregnancyEducationActions
    let presentationActive: Bool
    private struct ReferenceRequest: Equatable {
        let selectedID: String?
        let active: Bool
    }
    @State private var loadIdentity = UUID()

    @State private var selectedID = Prompt26PregnancyEducationCatalog.fetalReferencePeriods.first?.id
    @State private var content: Prompt26ApprovedContent?
    @State private var isLoading = false
    @State private var isUnavailable = false

    private var selectedPeriod: Prompt26DevelopmentReferencePeriod? {
        guard let selectedID else { return nil }
        return Prompt26PregnancyEducationCatalog.fetalReferencePeriods.first(where: { $0.id == selectedID })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FruitfolioFixedText(source: "development reference", font: .headline, color: Prompt26Palette.burgundy, serious: true)

            Picker(selection: Binding(get: { selectedID }, set: { if presentationActive { selectedID = $0 } })) {
                ForEach(Prompt26PregnancyEducationCatalog.fetalReferencePeriods) { period in
                    Text(verbatim: FruitfolioSemanticDocument.plainText(from: referenceDisplay(period).text))
                        .tag(Optional(period.id))
                }
            } label: {
                FruitfolioFixedText(source: "Development reference", font: .body, color: Prompt26Palette.burgundy, serious: true)
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("pregnancy.developmentReference")
            if let referenceCaption {
                Text(verbatim: settings.localized(referenceCaption)).font(.caption2)
            }

            if let period = selectedPeriod {
                Prompt26CanonicalImage(
                    asset: period.illustrationAsset,
                    altText: period.altText,
                    maxHeight: 300
                )

                FruitfolioFixedText(source: "Reference education only — this is not a personalized pregnancy week or developmental clock.", font: .footnote, color: Prompt26Palette.burgundy.opacity(0.72), serious: true)
                    .fixedSize(horizontal: false, vertical: true)

                if isLoading {
                    ProgressView {
                        FruitfolioFixedText(source: "opening approved research…", font: .footnote, color: Prompt26Palette.burgundy, serious: true)
                    }
                } else if isUnavailable {
                    FruitfolioFixedText(source: "Approved reference content is unavailable right now.", font: .footnote, color: Prompt26Palette.burgundy.opacity(0.74), serious: true)
                } else if let content {
                    FruitfolioTranslatedText(source: content.summary, protectedLiterals: content.sourceIDs, font: .body, color: Prompt26Palette.burgundy, serious: true)
                        .font(.body)
                        .foregroundStyle(Prompt26Palette.burgundy)
                        .fixedSize(horizontal: false, vertical: true)

                    let sourceIDs = Array(Set(content.sourceIDs + content.sections.flatMap(\.sourceIDs))).sorted()
                    if !sourceIDs.isEmpty {
                        Button {
                            guard presentationActive else { return }
                            actions.openSources(sourceIDs)
                        } label: {
                            FruitfolioFixedText(source: "sources · \(sourceIDs.count)", protectedLiterals: [String(sourceIDs.count)], font: .custom("Chalkboard SE", size: 13, relativeTo: .subheadline).bold(), color: Prompt26Palette.burgundy, serious: true)
                        }
                        .buttonStyle(Prompt26PaperButtonStyle())
                    }
                }
            }
        }
        .padding(16)
        .background(Prompt26Palette.card.opacity(0.55), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .task(id: ReferenceRequest(selectedID: selectedID, active: presentationActive)) {
            guard presentationActive else { return }
            await loadSelectedReference()
        }
        .onChange(of: presentationActive) { _, active in
            if !active { loadIdentity = UUID(); isLoading = false }
        }
        .onDisappear { loadIdentity = UUID(); isLoading = false }
        .task(id: FruitfolioControlTranslationState.TaskKey(
            key: .init(source: "pregnancy development reference options", language: settings.language),
            inferenceAllowed: settings.translationInferenceAllowed)) {
            for (period, state) in zip(Prompt26PregnancyEducationCatalog.fetalReferencePeriods, referenceStates) {
                guard !Task.isCancelled else { return }
                await state.resolve(referenceKey(period), inferenceAllowed: settings.translationInferenceAllowed)
            }
        }
    }

    @MainActor
    private func loadSelectedReference() async {
        guard presentationActive else { return }
        let identity = UUID()
        loadIdentity = identity
        let requestedID = selectedID
        content = nil
        isUnavailable = false
        guard let period = selectedPeriod else { isLoading = false; return }
        isLoading = true
        defer { if loadIdentity == identity { isLoading = false } }

        do {
            let loaded = try await provider.approvedContent(for: period.contentID)
            guard !Task.isCancelled, loadIdentity == identity, selectedID == requestedID else { return }
            guard loaded.contentID == period.contentID else { isUnavailable = true; return }
            content = loaded
        } catch {
            guard !Task.isCancelled, loadIdentity == identity, selectedID == requestedID else { return }
            isUnavailable = true
        }
    }
}

private struct Prompt26RelatedTopics: View {
    let topic: Prompt26PregnancyEducationTopic

    var body: some View {
        if !topic.relatedTopicIDs.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                FruitfolioFixedText(source: "related education", font: .custom("Chalkboard SE", size: 17, relativeTo: .headline).weight(.bold), color: Prompt26Palette.burgundy, serious: true)

                ForEach(topic.relatedTopicIDs) { relatedID in
                    let related = Prompt26PregnancyEducationCatalog.topic(relatedID)
                    NavigationLink(value: relatedID) {
                        HStack {
                            FruitfolioFixedText(source: related.title, font: .custom("Chalkboard SE", size: 13, relativeTo: .subheadline).bold(), color: Prompt26Palette.burgundy, serious: true)
                            Spacer()
                            Image("control_next")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .accessibilityHidden(true)
                        }
                    }
                    .buttonStyle(Prompt26PaperButtonStyle())
                }
            }
        }
    }
}

private struct Prompt26ActionRow: View {
    let topic: Prompt26PregnancyEducationTopic
    let content: Prompt26ApprovedContent?
    let actions: Prompt26PregnancyEducationActions
    let interactionAllowed: () -> Bool

    var sourceIDs: [String] {
        Array(Set((content?.sourceIDs ?? []) + contentSectionsSourceIDs)).sorted()
    }

    private var contentSectionsSourceIDs: [String] {
        content?.sections.flatMap(\.sourceIDs) ?? []
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                guard interactionAllowed() else { return }
                let entry = Prompt26SavedEducationEntry(
                    topicID: topic.id,
                    title: content?.title ?? topic.title,
                    contentID: content?.contentID ?? topic.shortContentID,
                    sourceIDs: sourceIDs
                )
                actions.saveEducationEntry(entry)
            } label: {
                FruitfolioFixedText(source: "save", font: .custom("Chalkboard SE", size: 13, relativeTo: .subheadline).bold(), color: Prompt26Palette.burgundy, serious: true)
            }
            .buttonStyle(Prompt26PaperButtonStyle())

            if !sourceIDs.isEmpty {
                Button {
                    guard interactionAllowed() else { return }
                    actions.openSources(sourceIDs)
                } label: {
                    FruitfolioFixedText(source: "sources · \(sourceIDs.count)", protectedLiterals: [String(sourceIDs.count)], font: .custom("Chalkboard SE", size: 13, relativeTo: .subheadline).bold(), color: Prompt26Palette.burgundy, serious: true)
                }
                .buttonStyle(Prompt26PaperButtonStyle())
            }
        }
    }
}

private struct Prompt26EducationBoundaryNotice: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FruitfolioFixedText(source: "pregnancy education stays intentional", font: .headline, color: Prompt26Palette.burgundy, serious: true)
            FruitfolioFixedText(source: "Fruitfolio does not surface pregnancy-specific imagery from cycle predictions, symptoms, notifications, or background recommendations.", protectedLiterals: ["Fruitfolio"], font: .body, color: Prompt26Palette.burgundy, serious: true)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Prompt26Palette.burgundy)
        .padding(16)
        .background(Prompt26Palette.card.opacity(0.62), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct Prompt26CanonicalImage: View {
    let asset: Prompt26PregnancyAsset
    let altText: String
    let maxHeight: CGFloat

    var body: some View {
        FruitfolioScientificIllustration(imageName: asset.imageName,
            accessibilityDescription: altText, maximumWidth: 420, maximumHeight: maxHeight)
            .frame(maxWidth: .infinity)
    }
}

private enum Prompt26Palette {
    static let burgundy = Color(red: 128.0 / 255.0, green: 0, blue: 0)
    static let paper = Color(red: 0.985, green: 0.963, blue: 0.915)
    static let card = Color(red: 0.973, green: 0.900, blue: 0.834)
}

private struct Prompt26SoftPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(FruitfolioButtonPopEffect(isPressed: configuration.isPressed, reduceMotion: reduceMotion))
    }
}

private struct Prompt26PaperButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Chalkboard SE", size: 13, relativeTo: .subheadline).weight(.bold))
            .foregroundStyle(Prompt26Palette.burgundy)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(Prompt26Palette.card.opacity(configuration.isPressed ? 0.84 : 0.62), in: Capsule())
            .modifier(FruitfolioButtonPopEffect(isPressed: configuration.isPressed, reduceMotion: reduceMotion))
    }
}
#endif
