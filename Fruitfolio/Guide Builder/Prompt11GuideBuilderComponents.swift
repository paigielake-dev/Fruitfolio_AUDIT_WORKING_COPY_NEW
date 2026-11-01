import SwiftUI

struct Prompt11GuideIconButton: View {
    let assetName: String
    let identificationWord: String
    let accessibilityLabel: String
    let reduceMotion: Bool
    let width: CGFloat
    let action: () -> Void

    init(
        assetName: String,
        identificationWord: String,
        accessibilityLabel: String,
        reduceMotion: Bool,
        width: CGFloat = 36,
        action: @escaping () -> Void
    ) {
        self.assetName = assetName
        self.identificationWord = identificationWord
        self.accessibilityLabel = accessibilityLabel
        self.reduceMotion = reduceMotion
        self.width = width
        self.action = action
    }

    var body: some View {
        Prompt11PressBounce(
            reduceMotion: reduceMotion
        ) {
            FruitfolioIconActionSurface(
                identificationWord: identificationWord,
                accessibilityLabel: accessibilityLabel,
                action: action
            ) {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: width)
                    .accessibilityHidden(true)
            }
        }
        .frame(
            minWidth: DesignTokens.Layout.minimumHitTarget,
            minHeight: DesignTokens.Layout.minimumHitTarget
        )
    }
}

struct Prompt11GuideBookTile: View {
    let encyclopedia: Prompt10Encyclopedia
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(encyclopedia.style.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 78, height: 112)
                    .accessibilityHidden(true)

                VStack(spacing: 3) {
                    Text(encyclopedia.name)
                        .font(.custom("Chalkboard SE", size: 12))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    if let subtitle = encyclopedia.subtitle,
                       !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(subtitle)
                            .font(.custom("Chalkboard SE", size: 8.5))
                            .foregroundStyle(
                                DesignTokens.ColorToken.secondaryBurgundy
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }
                .frame(maxWidth: 132)

                Text(
                    "\(encyclopedia.savedPageCount) \(encyclopedia.savedPageCount == 1 ? "page" : "pages")"
                )
                .font(.custom("Chalkboard SE", size: 10.5))
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: reduceMotion
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            "\(encyclopedia.name). \(encyclopedia.savedPageCount) saved pages."
        )
        .accessibilityHint("Double tap to open guide.")
    }
}

struct Prompt11NewGuideTile: View {
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image("guide_folder_add")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 122)
                    .accessibilityHidden(true)

                Text("make a new guide")
                    .font(.custom("Chalkboard SE", size: 11.5))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: reduceMotion
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Make a new guide")
    }
}

struct Prompt11SectionDivider: View {
    let title: String
    let pageCount: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                Spacer()

                Text("\(pageCount)")
                    .font(.custom("Chalkboard SE", size: 11))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
            }

            Image("guide_star_divider")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 190)
                .accessibilityHidden(true)
        }
    }
}

struct Prompt11SavedPagePaper: View {
    let page: Prompt10SavedPage
    let pageNumber: Int?
    let sourceStillExists: Bool
    let onAddNote: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(page.question.isEmpty ? "saved page" : page.question)
                    .font(.custom("Chalkboard SE", size: 15))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                Spacer()

                if let pageNumber {
                    Text("\(pageNumber)")
                        .font(.custom("Chalkboard SE", size: 10))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }
            }

            if page.saveType == .excerpt {
                Text("saved excerpt")
                    .font(.custom("Chalkboard SE", size: 10.5))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
            }

            if !sourceStillExists,
               page.sourceSavedPageID != nil {
                Text("this saved page is no longer in your library")
                    .font(.custom("Chalkboard SE", size: 11))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
            }

            FruitfolioSemanticText(document: page.resolvedSemanticDocument,
                baseFont: .custom("Chalkboard SE", size: 13.5, relativeTo: .body))
                .font(.custom("Chalkboard SE", size: 13.5))
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Prompt10SavedCitationsView(page: page)

            if !page.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("my note")
                        .font(.custom("Chalkboard SE", size: 11))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )

                    Text(page.notes)
                        .font(.custom("Chalkboard SE", size: 12))
                        .italic()
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }
                .padding(10)
                .background(
                    DesignTokens.ColorToken.backgroundCream.opacity(0.72),
                    in: RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )
            }

            if let onAddNote {
                Button("add a note") {
                    onAddNote()
                }
                .font(.custom("Chalkboard SE", size: 11))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .frame(
                    minHeight: DesignTokens.Layout.minimumHitTarget,
                    alignment: .leading
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            DesignTokens.ColorToken.backgroundCream.opacity(0.94),
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                DesignTokens.ColorToken.secondaryBurgundy.opacity(0.09),
                lineWidth: 0.8
            )
        }
    }
}

private struct Prompt11PressBounce<Content: View>: View {
    let reduceMotion: Bool

    @ViewBuilder
    let content: () -> Content

    @GestureState private var isPressed = false

    var body: some View {
        content()
            .scaleEffect(
                reduceMotion ? 1.0 : (isPressed ? 0.88 : 1.0)
            )
            .offset(
                y: reduceMotion ? 0 : (isPressed ? 5 : 0)
            )
            .rotationEffect(
                .degrees(
                    reduceMotion ? 0 : (isPressed ? -1.2 : 0)
                )
            )
            .brightness(isPressed ? -0.04 : 0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.08)
                    : .spring(
                        response: 0.20,
                        dampingFraction: 0.38,
                        blendDuration: 0
                    ),
                value: isPressed
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}
