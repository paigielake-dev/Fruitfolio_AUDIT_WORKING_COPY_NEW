#if canImport(SwiftUI)
import SwiftUI
import UIKit

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
                FruitfolioScientificIllustration(imageName: asset.imageName,
                    accessibilityDescription: asset.altText, maximumWidth: maximumWidth,
                    interactiveOverlay: hotspots.isEmpty ? nil : AnyView(
                        Prompt27ScientificHotspotOverlay(hotspots: hotspots, onSelect: onHotspotSelect)
                    ))
                    .frame(maxWidth: maximumWidth)
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
                .buttonStyle(CutePopButtonStyle())
                .modifier(FruitfolioFixedAccessibilityLabel(source: hotspot.label))
                .modifier(FruitfolioFixedAccessibilityHint(source: "Opens educational detail"))
                .position(
                    x: proxy.size.width * hotspot.normalizedX,
                    y: proxy.size.height * hotspot.normalizedY
                )
            }
        }
    }
}

struct Prompt27ContextualScienceSectionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var viewIsVisible = false
    private var canInteract: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
            && popupCoordinator.currentPopup == nil
    }
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
                    .modifier(FruitfolioFixedAccessibilityLabel(source: "Loading educational content"))

            case let .loaded(content, route):
                loadedView(
                    content: content,
                    route: route
                )

            case .unavailable:
                unavailableView
            }
        }
        .disabled(!canInteract)
        .onAppear { viewIsVisible = true }
        .onDisappear { viewIsVisible = false; viewModel.suspendPresentation() }
        .task(id: canInteract) {
            guard canInteract else { viewModel.suspendPresentation(); return }
            if let request = viewModel.loadIfNeeded() { await request.value }
        }
        .onChange(of: canInteract) { _, active in
            if !active { viewModel.suspendPresentation() }
        }
    }

    @ViewBuilder
    private func loadedView(
        content: Prompt27ApprovedScienceContent,
        route: Prompt27ScienceVisualRoute
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                FruitfolioFixedText(source: viewModel.section.title, font: .custom("Chalkboard SE", size: 23, relativeTo: .title2).weight(.bold), color: DesignTokens.ColorToken.primaryBurgundy, serious: true)
                    .fixedSize(horizontal: false, vertical: true)

                if route.primaryAsset != nil {
                    Prompt27ScientificPlateView(
                        route: route,
                        hotspots: visibleHotspots,
                        onHotspotSelect: { hotspot in
                            guard canInteract else { return }
                            viewModel.selectHotspot(hotspot.id)
                            actions.openHotspotContent(hotspot.educationalContentID)
                        }
                    )
                    .frame(maxWidth: .infinity)
                }

                FruitfolioTranslatedText(source: content.body, protectedLiterals: content.sourceIDs, font: .custom("Chalkboard SE", size: 15, relativeTo: .body))
                    .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
                    .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                HStack(spacing: 16) {
                    Button {
                        guard canInteract else { return }
                        actions.showSources(content.sourceIDs)
                    } label: {
                        FruitfolioFixedText(source: "sources", font: .custom("Chalkboard SE", size: 14, relativeTo: .body), color: DesignTokens.ColorToken.primaryBurgundy, serious: true)
                    }
                    .frame(minHeight: 44)
                    .modifier(FruitfolioFixedAccessibilityHint(source: "Shows sources for this educational section"))

                    Button {
                        guard canInteract else { return }
                        actions.saveEducationalContent(content)
                    } label: {
                        FruitfolioFixedText(source: "save", font: .custom("Chalkboard SE", size: 14, relativeTo: .body), color: DesignTokens.ColorToken.primaryBurgundy, serious: true)
                    }
                    .frame(minHeight: 44)
                    .modifier(FruitfolioFixedAccessibilityHint(source: "Saves this educational content"))
                }
                .buttonStyle(CutePopButtonStyle())
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
    }

    private var visibleHotspots: [Prompt27ScienceHotspot] {
        let allowedIDs = Set(viewModel.section.hotspotIDs)
        var seen = Set<String>()
        return hotspots.filter {
            allowedIDs.contains($0.id) && $0.hasValidCanvasPlacement && seen.insert($0.id).inserted
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 14) {
            FruitfolioImage(id: .fruit_blueberry_friendly)
                .scaledToFit()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            FruitfolioFixedText(source: "this science page isn’t available right now.", font: .custom("Chalkboard SE", size: 14, relativeTo: .body), color: DesignTokens.ColorToken.primaryBurgundy, serious: true)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                guard canInteract else { return }
                viewModel.retry()
            } label: {
                FruitfolioFixedText(source: "try again", font: .custom("Chalkboard SE", size: 14, relativeTo: .body), color: DesignTokens.ColorToken.primaryBurgundy, serious: true)
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
