import SwiftUI

struct Prompt10BookTile: View {
    let encyclopedia: Prompt10Encyclopedia
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                Image(encyclopedia.style.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 116, height: 142)
                    .accessibilityHidden(true)

                Text(encyclopedia.name)
                    .font(.custom("Chalkboard SE", size: 14))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: 132)

                Text(metadataText)
                    .font(.custom("Chalkboard SE", size: 10.5))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
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
        .accessibilityLabel(
            "\(encyclopedia.name), \(metadataText)"
        )
        .accessibilityHint(
            "Opens this encyclopedia"
        )
    }

    private var metadataText: String {
        let chapters = encyclopedia.chapterCount
        let pages = encyclopedia.savedPageCount

        let chapterWord = chapters == 1 ? "chapter" : "chapters"
        let pageWord = pages == 1 ? "page" : "pages"

        return "\(chapters) \(chapterWord) · \(pages) \(pageWord)"
    }
}

struct Prompt10LibraryHero: View {
    let isEmpty: Bool

    var body: some View {
        ZStack {
            Prompt10LibraryAssetImage(
                asset: .bookshelf
            )
            .frame(maxWidth: 310)
            .accessibilityHidden(true)

            if !isEmpty {
                HStack {
                    Prompt10LibraryAssetImage(
                        asset: .bookStack
                    )
                    .frame(width: 72)
                    .accessibilityHidden(true)

                    Spacer()

                    Prompt10LibraryAssetImage(
                        asset: .pottedPlant
                    )
                    .frame(width: 64)
                    .accessibilityHidden(true)
                }
                .padding(.horizontal, 12)
                .offset(y: 48)
            }
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
            Text("find")
                .font(.custom("Chalkboard SE", size: 11))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )

            TextField(
                "find an encyclopedia…",
                text: $text
            )
            .font(.custom("Chalkboard SE", size: 13))
            .foregroundStyle(
                DesignTokens.ColorToken.primaryBurgundy
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(false)

            if !text.isEmpty {
                Button("clear") {
                    text = ""
                }
                .font(.custom("Chalkboard SE", size: 10.5))
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .buttonStyle(.plain)
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
            .accessibilityLabel(
                "Sort, \(sort.label)"
            )

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
            let paperWidth = min(max(proxy.size.width - 32, 280), 340)
            let safeBodyWidth = paperWidth * 0.80

            ZStack {
                DesignTokens.ColorToken.primaryBurgundy
                    .opacity(0.10)
                    .ignoresSafeArea()

                ZStack(alignment: .center) {
                    Image("popup_notebook_paper")
                        .resizable()
                        .scaledToFit()
                        .frame(width: paperWidth)
                        .accessibilityHidden(true)

                    content()
                        .frame(width: safeBodyWidth, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 30)
                }
                .frame(width: paperWidth, alignment: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}
