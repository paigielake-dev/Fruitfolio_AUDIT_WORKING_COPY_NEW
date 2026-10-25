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
    let provider: any Prompt26PregnancyResearchProviding
    let actions: Prompt26PregnancyEducationActions
    let entryContext: Prompt26PregnancyEntryContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("pregnancy")
                        .font(.custom("Chalkboard SE", size: 30, relativeTo: .largeTitle).weight(.bold))
                        .foregroundStyle(Prompt26Palette.burgundy)
                    Text("A research-based guide to pregnancy biology, testing, development, prenatal care concepts, and the structures that support pregnancy.")
                        .font(.body)
                        .foregroundStyle(Prompt26Palette.burgundy.opacity(0.82))
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
                Text(topic.title)
                    .font(.custom("Chalkboard SE", size: 17, relativeTo: .headline).weight(.bold))
                    .foregroundStyle(Prompt26Palette.burgundy)
                Text(topic.subtitle)
                    .font(.custom("Chalkboard SE", size: 13, relativeTo: .subheadline))
                    .foregroundStyle(Prompt26Palette.burgundy.opacity(0.75))
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
        .accessibilityLabel("\(topic.title). \(topic.subtitle)")
        .accessibilityHint("Opens educational reference")
    }
}

private struct Prompt26PregnancyTopicView: View {
    @StateObject private var model: Prompt26PregnancyEducationViewModel
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    Text(model.topic.title)
                        .font(.custom("Chalkboard SE", size: 30, relativeTo: .largeTitle).weight(.bold))
                        .foregroundStyle(Prompt26Palette.burgundy)
                    Text(model.topic.subtitle)
                        .font(.body)
                        .foregroundStyle(Prompt26Palette.burgundy.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if model.topic.id == .fetalDevelopment {
                    Prompt26FetalReferenceSection(provider: modelProvider, actions: actions)
                } else {
                    Prompt26HeroIllustration(topic: model.topic)
                }

                Prompt26ContentBody(
                    state: model.state,
                    isExpanded: $isExpanded,
                    retry: model.retry
                )

                if model.topic.id == .earlyDevelopment {
                    Button("open fertilization education") {
                        actions.openFertilizationEducation()
                    }
                    .buttonStyle(Prompt26PaperButtonStyle())
                }

                Prompt26RelatedTopics(topic: model.topic)

                Prompt26ActionRow(
                    topic: model.topic,
                    content: model.loadedContent,
                    actions: actions
                )
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.vertical, 28)
        }
        .background(Prompt26Palette.paper.ignoresSafeArea())
        .navigationTitle(model.topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { model.loadIfNeeded() }
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
                Text("opening approved research…")
                    .font(.subheadline)
                    .foregroundStyle(Prompt26Palette.burgundy.opacity(0.74))
            }
            .accessibilityElement(children: .combine)

        case .unavailable:
            VStack(alignment: .leading, spacing: 12) {
                Text("approved research is unavailable right now")
                    .font(.custom("Chalkboard SE", size: 17, relativeTo: .headline).weight(.bold))
                    .foregroundStyle(Prompt26Palette.burgundy)
                Text("Fruitfolio won’t fill pregnancy medicine from unsupported model knowledge. Try again when the Research Library is available.")
                    .font(.body)
                    .foregroundStyle(Prompt26Palette.burgundy.opacity(0.76))
                Button("try again", action: retry)
                    .buttonStyle(Prompt26PaperButtonStyle())
            }
            .padding(16)
            .background(Prompt26Palette.card.opacity(0.64), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        case let .loaded(content):
            VStack(alignment: .leading, spacing: 16) {
                Text(content.summary)
                    .font(.body)
                    .foregroundStyle(Prompt26Palette.burgundy)
                    .fixedSize(horizontal: false, vertical: true)

                if !content.sections.isEmpty {
                    Button(isExpanded ? "show less" : "learn more") {
                        isExpanded.toggle()
                    }
                    .buttonStyle(Prompt26PaperButtonStyle())

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(content.sections) { section in
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(section.heading)
                                        .font(.headline)
                                        .foregroundStyle(Prompt26Palette.burgundy)
                                    Text(section.body)
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
    let provider: any Prompt26PregnancyResearchProviding
    let actions: Prompt26PregnancyEducationActions

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
            Text("development reference")
                .font(.headline)
                .foregroundStyle(Prompt26Palette.burgundy)

            Picker("Development reference", selection: $selectedID) {
                ForEach(Prompt26PregnancyEducationCatalog.fetalReferencePeriods) { period in
                    Text(period.displayRange).tag(Optional(period.id))
                }
            }
            .pickerStyle(.menu)

            if let period = selectedPeriod {
                Prompt26CanonicalImage(
                    asset: period.illustrationAsset,
                    altText: period.altText,
                    maxHeight: 300
                )

                Text("Reference education only — this is not a personalized pregnancy week or developmental clock.")
                    .font(.footnote)
                    .foregroundStyle(Prompt26Palette.burgundy.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                if isLoading {
                    ProgressView("opening approved research…")
                        .font(.footnote)
                } else if isUnavailable {
                    Text("Approved reference content is unavailable right now.")
                        .font(.footnote)
                        .foregroundStyle(Prompt26Palette.burgundy.opacity(0.74))
                } else if let content {
                    Text(content.summary)
                        .font(.body)
                        .foregroundStyle(Prompt26Palette.burgundy)
                        .fixedSize(horizontal: false, vertical: true)

                    let sourceIDs = Array(Set(content.sourceIDs + content.sections.flatMap(\.sourceIDs))).sorted()
                    if !sourceIDs.isEmpty {
                        Button("sources · \(sourceIDs.count)") {
                            actions.openSources(sourceIDs)
                        }
                        .buttonStyle(Prompt26PaperButtonStyle())
                    }
                }
            }
        }
        .padding(16)
        .background(Prompt26Palette.card.opacity(0.55), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .task(id: selectedID) {
            await loadSelectedReference()
        }
    }

    @MainActor
    private func loadSelectedReference() async {
        content = nil
        isUnavailable = false
        guard let period = selectedPeriod else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let loaded = try await provider.approvedContent(for: period.contentID)
            guard !Task.isCancelled else { return }
            content = loaded
        } catch {
            guard !Task.isCancelled else { return }
            isUnavailable = true
        }
    }
}

private struct Prompt26RelatedTopics: View {
    let topic: Prompt26PregnancyEducationTopic

    var body: some View {
        if !topic.relatedTopicIDs.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("related education")
                    .font(.custom("Chalkboard SE", size: 17, relativeTo: .headline).weight(.bold))
                    .foregroundStyle(Prompt26Palette.burgundy)

                ForEach(topic.relatedTopicIDs) { relatedID in
                    let related = Prompt26PregnancyEducationCatalog.topic(relatedID)
                    NavigationLink(value: relatedID) {
                        HStack {
                            Text(related.title)
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

    var sourceIDs: [String] {
        Array(Set((content?.sourceIDs ?? []) + contentSectionsSourceIDs)).sorted()
    }

    private var contentSectionsSourceIDs: [String] {
        content?.sections.flatMap(\.sourceIDs) ?? []
    }

    var body: some View {
        HStack(spacing: 12) {
            Button("save") {
                let entry = Prompt26SavedEducationEntry(
                    topicID: topic.id,
                    title: content?.title ?? topic.title,
                    contentID: content?.contentID ?? topic.shortContentID,
                    sourceIDs: sourceIDs
                )
                actions.saveEducationEntry(entry)
            }
            .buttonStyle(Prompt26PaperButtonStyle())

            if !sourceIDs.isEmpty {
                Button("sources · \(sourceIDs.count)") {
                    actions.openSources(sourceIDs)
                }
                .buttonStyle(Prompt26PaperButtonStyle())
            }
        }
    }
}

private struct Prompt26EducationBoundaryNotice: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("pregnancy education stays intentional")
                .font(.headline)
            Text("Fruitfolio does not surface pregnancy-specific imagery from cycle predictions, symptoms, notifications, or background recommendations.")
                .font(.body)
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
        Group {
#if canImport(UIKit)
            if UIImage(named: asset.imageName) != nil {
                image
            } else {
                missingArt
            }
#else
            image
#endif
        }
    }

    private var image: some View {
        Image(asset.imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(maxHeight: maxHeight)
            .accessibilityLabel(altText)
    }

    private var missingArt: some View {
        Text("required artwork unavailable")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Prompt26Palette.burgundy)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Prompt26Palette.card.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityLabel("Required Pregnancy Education artwork is unavailable")
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
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.10), value: configuration.isPressed)
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
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.10), value: configuration.isPressed)
    }
}
#endif
