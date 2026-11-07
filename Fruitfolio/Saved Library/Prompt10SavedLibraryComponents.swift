import SwiftUI

struct Prompt10BookTile: View {
    let encyclopedia: Prompt10Encyclopedia
    let reduceMotion: Bool
    let action: () -> Void
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        let copy = Prompt10BookTileCopy(name: encyclopedia.name, subtitle: encyclopedia.subtitle,
            chapters: encyclopedia.chapterCount, pages: encyclopedia.savedPageCount, language: settings.language)
        return Button {
            action()
        } label: {
            VStack(spacing: 8) {
                Prompt10ContinuousBook(style: encyclopedia.style, reveal: 0, openness: 0)
                    .frame(width: 116, height: 142)
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(key: Prompt10BookFramePreference.self,
                                value: [encyclopedia.id: geometry.frame(in: .named("Prompt10BookSpace"))])
                        }
                    }

                Text(verbatim: encyclopedia.name)
                    .font(.custom("Chalkboard SE", size: 14))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 132)

                if let description = encyclopedia.subtitle, !description.isEmpty {
                    Text(verbatim: description)
                        .font(.custom("Chalkboard SE", size: 12, relativeTo: .caption))
                        .foregroundStyle(DesignTokens.ColorToken.secondaryBurgundy)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 132)
                }

                FruitfolioFixedText(source: copy.metadataSource, protectedLiterals: copy.numericLiterals,
                    font: .custom("Chalkboard SE", size: 10.5, relativeTo: .caption),
                    color: DesignTokens.ColorToken.secondaryBurgundy)
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 194,
                alignment: .top
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: reduceMotion
            )
        )
        .modifier(FruitfolioFixedAccessibilityLabel(source: copy.accessibilitySource,
            protectedLiterals: copy.accessibilityProtectedLiterals))
        .modifier(FruitfolioFixedAccessibilityHint(source: "Opens this encyclopedia"))
    }

}

struct Prompt10LibraryHero: View {
    var body: some View {
        ZStack {
            Prompt10LibraryAssetImage(
                asset: .bookshelf
            )
            .frame(maxWidth: 310)
            .accessibilityHidden(true)


        }
        .frame(
            maxWidth: .infinity,
            minHeight: 170,
            maxHeight: 210
        )
    }
}

struct Prompt10QuietSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            FruitfolioFixedText(source: "find", font: .custom("Chalkboard SE", size: 11, relativeTo: .body),
                color: DesignTokens.ColorToken.secondaryBurgundy)
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )

            FruitfolioFixedTextField(
                "find an encyclopedia…",
                text: $text
            )
            .font(.custom("Chalkboard SE", size: 13))
            .foregroundStyle(
                DesignTokens.ColorToken.primaryBurgundy
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(false)
            .accessibilityIdentifier("library.search.input")

            if !text.isEmpty {
                FruitfolioControlPillButton(label: "clear") { text = "" }
                .controlSize(.small)
                .frame(maxWidth: 104)
                .accessibilityIdentifier("library.search.clear")
                .frame(
                    minWidth: DesignTokens.Layout.minimumHitTarget,
                    minHeight: DesignTokens.Layout.minimumHitTarget
                )
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                DesignTokens.ColorToken.backgroundCream.opacity(0.92)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    DesignTokens.ColorToken.primaryBurgundy.opacity(0.12),
                    lineWidth: 1
                )
            }
        }
    }
}

struct Prompt10SortPicker: View {
    @Binding var sort: Prompt10LibrarySort
    let reduceMotion: Bool
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 6) {
            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 6) {
                    Text("sort")
                        .fontWeight(.bold)

                    Text(sort.label)

                    Text(expanded ? "⌃" : "⌄")
                        .accessibilityHidden(true)
                }
                .font(.custom("Chalkboard SE", size: 11))
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .frame(
                    minHeight: DesignTokens.Layout.minimumHitTarget
                )
                .padding(.horizontal, 12)
            }
            .buttonStyle(
                CutePopButtonStyle(
                    reduceMotion: reduceMotion
                )
            )
            .accessibilityLabel("sort encyclopedias")
            .accessibilityValue("\(sort.label), \(expanded ? "expanded" : "collapsed")")
            .accessibilityHint(expanded ? "hides sorting choices" : "shows sorting choices")

            if expanded {
                VStack(spacing: 2) {
                    ForEach(Prompt10LibrarySort.allCases) { option in
                        Button {
                            sort = option
                            withAnimation(
                                reduceMotion
                                    ? .easeOut(duration: 0.12)
                                    : .easeOut(duration: 0.22)
                            ) {
                                expanded = false
                            }
                        } label: {
                            HStack {
                                Text(option.label)
                                    .font(
                                        .custom(
                                            "Chalkboard SE",
                                            size: 11
                                        )
                                    )

                                Spacer()

                                if option == sort {
                                    Text("✓")
                                        .accessibilityHidden(true)
                                }
                            }
                            .foregroundStyle(
                                DesignTokens.ColorToken.primaryBurgundy
                            )
                            .frame(
                                minHeight: DesignTokens.Layout.minimumHitTarget
                            )
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.label)
                        .accessibilityAddTraits(option == sort ? .isSelected : [])
                    }
                }
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .fill(
                        DesignTokens.ColorToken.backgroundCream
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                        .stroke(
                            DesignTokens.ColorToken.primaryBurgundy.opacity(0.12),
                            lineWidth: 1
                        )
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

struct Prompt10WatercolorPopup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let available = CGSize(
                width: proxy.size.width,
                height: max(0, proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom)
            )
            let metrics = FruitfolioPopupLayout.notebook(available: available)

            ZStack {
                // Parent screens own the canonical dim/blur. A second tint here
                // used to produce different-looking Library and Guide popups.
                Color.clear.contentShape(Rectangle())

                ZStack {
                    Image("popup_notebook_paper")
                        .resizable()
                        .scaledToFit()
                        .frame(width: metrics.paperSize.width, height: metrics.paperSize.height)
                        .accessibilityHidden(true)

                    ScrollView(.vertical) {
                        content()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .frame(minHeight: metrics.writingSize.height, alignment: .center)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDismissesKeyboard(.interactively)
                    .frame(width: metrics.writingSize.width, height: metrics.writingSize.height)
                    .accessibilityIdentifier("fruitfolio.notebookPopup.scroll")
                }
                .frame(width: metrics.paperSize.width, height: metrics.paperSize.height)
                .accessibilityElement(children: .contain)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

extension View {
    func bookLabelGuidance(text: String, maximum: Int) -> some View {
        modifier(Prompt10BookLabelGuidanceModifier(text: text, maximum: maximum))
    }
}

private struct Prompt10BookLabelGuidanceModifier: ViewModifier {
    let text: String
    let maximum: Int
    @EnvironmentObject private var settings: SettingsStore
    func body(content: Content) -> some View {
        let locale = Locale(identifier: settings.language.localeIdentifier)
        let count = text.count.formatted(.number.locale(locale))
        let limit = maximum.formatted(.number.locale(locale))
        VStack(alignment: .leading, spacing: 5) {
            content.modifier(FruitfolioFixedAccessibilityHint(
                source: "maximum \(limit) characters; clinical and sexual-health terms are welcome",
                protectedLiterals: [limit]))
            FruitfolioFixedText(source: "\(count) / \(limit) characters",
                protectedLiterals: [count, limit], font: .caption,
                color: text.count > maximum ? Color.red : DesignTokens.ColorToken.secondaryBurgundy)
                .modifier(FruitfolioFixedAccessibilityLabel(source: "\(count) of \(limit) characters",
                    protectedLiterals: [count, limit]))
                .accessibilityIdentifier("library.bookLabelGuidance.count")
        }
    }
}
