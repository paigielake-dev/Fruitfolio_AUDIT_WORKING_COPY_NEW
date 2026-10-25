#if canImport(SwiftUI)
import SwiftUI

struct Prompt27ScientificPlateView: View {
    let route: Prompt27ScienceVisualRoute
    let hotspots: [Prompt27ScienceHotspot]
    let maximumWidth: CGFloat
    let onHotspotSelect: (Prompt27ScienceHotspot) -> Void

    init(
        route: Prompt27ScienceVisualRoute,
        hotspots: [Prompt27ScienceHotspot] = [],
        maximumWidth: CGFloat = 360,
        onHotspotSelect: @escaping (Prompt27ScienceHotspot) -> Void = { _ in }
    ) {
        self.route = route
        self.hotspots = hotspots
        self.maximumWidth = maximumWidth
        self.onHotspotSelect = onHotspotSelect
    }

    var body: some View {
        Group {
            if let asset = route.primaryAsset {
                Image(asset.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maximumWidth)
                    .overlay {
                        if !hotspots.isEmpty {
                            Prompt27ScientificHotspotOverlay(
                                hotspots: hotspots,
                                onSelect: onHotspotSelect
                            )
                        }
                    }
                    .accessibilityLabel(Text(asset.altText))
            }
        }
    }
}

struct Prompt27ScientificHotspotOverlay: View {
    let hotspots: [Prompt27ScienceHotspot]
    let onSelect: (Prompt27ScienceHotspot) -> Void

    var body: some View {
        GeometryReader { proxy in
            ForEach(hotspots) { hotspot in
                Button {
                    onSelect(hotspot)
                } label: {
                    Circle()
                        .fill(.clear)
                        .contentShape(Circle())
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(.primary.opacity(0.42), lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(hotspot.label))
                .accessibilityHint(Text("Opens educational detail"))
                .position(
                    x: proxy.size.width * hotspot.normalizedX,
                    y: proxy.size.height * hotspot.normalizedY
                )
            }
        }
    }
}

struct Prompt27ContextualScienceSectionView: View {
    @StateObject private var viewModel: Prompt27ScienceViewModel

    private let hotspots: [Prompt27ScienceHotspot]
    private let actions: Prompt27ScienceActions

    init(
        section: Prompt27ContextualScienceSection,
        provider: any Prompt27ScienceResearchProviding,
        router: Prompt27ContextRouter = .init(),
        hotspots: [Prompt27ScienceHotspot] = [],
        actions: Prompt27ScienceActions = .init()
    ) {
        _viewModel = StateObject(
            wrappedValue: Prompt27ScienceViewModel(
                section: section,
                provider: provider,
                router: router
            )
        )
        self.hotspots = hotspots
        self.actions = actions
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .accessibilityLabel(Text("Loading educational content"))

            case let .loaded(content, route):
                loadedView(
                    content: content,
                    route: route
                )

            case .unavailable:
                unavailableView
            }
        }
        .task {
            viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private func loadedView(
        content: Prompt27ApprovedScienceContent,
        route: Prompt27ScienceVisualRoute
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(viewModel.section.title)
                    .font(.custom("Chalkboard SE", size: 23, relativeTo: .title2).weight(.bold))
                    .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                    .fixedSize(horizontal: false, vertical: true)

                if route.primaryAsset != nil {
                    Prompt27ScientificPlateView(
                        route: route,
                        hotspots: visibleHotspots,
                        onHotspotSelect: { hotspot in
                            viewModel.selectHotspot(hotspot.id)
                            actions.openHotspotContent(hotspot.educationalContentID)
                        }
                    )
                    .frame(maxWidth: .infinity)
                }

                Text(content.body)
                    .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
                    .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                HStack(spacing: 16) {
                    Button("sources") {
                        actions.showSources(content.sourceIDs)
                    }
                    .frame(minHeight: 44)
                    .accessibilityHint(Text("Shows sources for this educational section"))

                    Button("save") {
                        actions.saveEducationalContent(content)
                    }
                    .frame(minHeight: 44)
                    .accessibilityHint(Text("Saves this educational content"))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
    }

    private var visibleHotspots: [Prompt27ScienceHotspot] {
        let allowedIDs = Set(viewModel.section.hotspotIDs)
        return hotspots.filter { allowedIDs.contains($0.id) }
    }

    private var unavailableView: some View {
        VStack(spacing: 14) {
            FruitfolioImage(id: .fruit_blueberry_friendly)
                .scaledToFit()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            Text("this science page isn’t available right now.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("try again") {
                viewModel.retry()
            }
            .frame(minHeight: 44)
        }
        .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .multilineTextAlignment(.center)
        .padding(24)
        .background(
            DesignTokens.ColorToken.backgroundCream.opacity(0.82),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .accessibilityElement(children: .contain)
    }
}
#endif
