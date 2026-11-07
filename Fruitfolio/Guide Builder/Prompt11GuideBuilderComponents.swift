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
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        let copy = Prompt11GuideTileCopy(name: encyclopedia.name, sections: encyclopedia.chapterCount,
            pages: encyclopedia.savedPageCount, language: settings.language)
        Button(action: action) {
            VStack(spacing: 7) {
                Image(encyclopedia.style.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 78, height: 112)
                    .accessibilityHidden(true)

                VStack(spacing: 3) {
                    Text(verbatim: encyclopedia.name)
                        .font(.custom("Chalkboard SE", size: 12))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = encyclopedia.subtitle,
                       !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(verbatim: subtitle)
                            .font(.custom("Chalkboard SE", size: 8.5))
                            .foregroundStyle(
                                DesignTokens.ColorToken.secondaryBurgundy
                            )
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: 132)

                FruitfolioFixedText(source: copy.counts.pagesSource, protectedLiterals: [copy.counts.pageCountLiteral],
                    font: .custom("Chalkboard SE", size: 10.5), color: DesignTokens.ColorToken.secondaryBurgundy)

            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: reduceMotion
            )
        )
        .modifier(FruitfolioFixedAccessibilityLabel(source: copy.accessibilitySource,
            protectedLiterals: copy.accessibilityProtectedLiterals))
        .modifier(FruitfolioFixedAccessibilityHint(source: "Double tap to open guide."))
        .accessibilityIdentifier("guide.book." + encyclopedia.id.uuidString)
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

                FruitfolioFixedText(source: "make a new guide", font: .custom("Chalkboard SE", size: 11.5).bold(),
                    color: DesignTokens.ColorToken.primaryBurgundy)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: reduceMotion
            )
        )
        .modifier(FruitfolioFixedAccessibilityLabel(source: "Make a new guide"))
    }
}

struct Prompt11SectionDivider: View {
    let title: String
    let pageCount: Int
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(verbatim: title)
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                Spacer()

                Text(verbatim: pageCount.formatted(.number.locale(Locale(identifier: settings.language.localeIdentifier))))
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
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Group {
                    if page.question.isEmpty {
                        FruitfolioFixedText(source: "saved page", font: .custom("Chalkboard SE", size: 15).bold(),
                            color: DesignTokens.ColorToken.primaryBurgundy)
                    } else {
                        Text(verbatim: page.question)
                            .font(.custom("Chalkboard SE", size: 15).bold())
                            .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("guide.paper.question." + page.id.uuidString)

                Spacer()

                if let pageNumber {
                    Text(verbatim: pageNumber.formatted(.number.grouping(.never).locale(Locale(identifier: settings.language.localeIdentifier))))
                        .accessibilityIdentifier("guide.paper.pageNumber." + page.id.uuidString)
                        .font(.custom("Chalkboard SE", size: 10))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }
            }

            if let provenance = page.userMaterial {
                FruitfolioFixedText(source: "your own material · not verified research", font: .caption.bold(), serious: true)
                if let address = provenance.sourceURL {
                    Text(verbatim: address).font(.caption).textSelection(.enabled)
                }
            }

            if page.saveType == .excerpt {
                FruitfolioFixedText(source: "saved excerpt", font: .custom("Chalkboard SE", size: 10.5).bold(),
                    color: DesignTokens.ColorToken.secondaryBurgundy)
                    .accessibilityIdentifier("guide.paper.excerptType." + page.id.uuidString)
            }

            if page.hasLegacyExcerptRemainder {
                FruitfolioFixedText(source: page.canReviewLegacyExcerptCleanup
                    ? "this older excerpt also retains the original answer. nothing has been removed."
                    : "this older excerpt retains answer text but has no recorded selection. it has been preserved for review.",
                    font: .caption, color: DesignTokens.ColorToken.secondaryBurgundy, serious: true)
                    .accessibilityIdentifier("guide.paper.legacyExcerptNotice." + page.id.uuidString)
            }

            if !sourceStillExists,
               page.sourceSavedPageID != nil {
                FruitfolioFixedText(source: "this saved page is no longer in your library",
                    font: .custom("Chalkboard SE", size: 11).bold(), color: DesignTokens.ColorToken.secondaryBurgundy, serious: true)
            }

            if !page.displayBody.isEmpty {
            FruitfolioTranslatedText(source: page.displayBody, protectedLiterals: page.sourceIDs,
                                     enabled: page.allowsAutomaticDisplayTranslation,
                                     font: .custom("Chalkboard SE", size: 14, relativeTo: .body),
                    sourceLanguage: page.displaySourceLanguage,
                    semanticSpans: page.displaySemanticSpans, sourceRecords: page.sourceRecords ?? [])
                .font(.custom("Chalkboard SE", size: 13.5))
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            }

            FruitfolioSavedScientificIllustrations(assetIDs: page.educationalAssetIDs ?? [])

            ForEach(page.importedImageIDs ?? [], id: \.self) { imageID in
                Prompt10ImportedImage(imageID: imageID)
            }

            if page.userMaterial == nil, let notice = page.evidenceSupport?.restricted(to: page.saveType).notice {
                FruitfolioFixedText(source: notice, font: .caption, color: DesignTokens.ColorToken.secondaryBurgundy, serious: true)
                    .accessibilityIdentifier("savedPage.evidenceSupport")
            }
            if let records = page.sourceRecords, !records.isEmpty {
                FruitfolioSourceCitationList(sources: records)
            } else if !page.sourceIDs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    FruitfolioFixedText(source: "sources", font: .custom("Chalkboard SE", size: 11).bold(),
                        color: DesignTokens.ColorToken.primaryBurgundy)

                    ForEach(Array(page.sourceIDs.enumerated()), id: \.offset) { offset, sourceID in
                        Text(verbatim: sourceID)
                            .accessibilityIdentifier("guide.paper.source." + page.id.uuidString + "." + String(offset))
                            .font(.custom("Chalkboard SE", size: 10))
                            .foregroundStyle(
                                DesignTokens.ColorToken.secondaryBurgundy
                            )
                    }
                }
            }

            if !page.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    FruitfolioFixedText(source: "my note", font: .custom("Chalkboard SE", size: 11).bold(),
                        color: DesignTokens.ColorToken.primaryBurgundy)

                    Text(verbatim: page.notes)
                        .accessibilityIdentifier("guide.paper.note." + page.id.uuidString)
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
                Button { onAddNote() } label: {
                    FruitfolioFixedText(source: "add a note", font: .custom("Chalkboard SE", size: 11).bold(),
                        color: DesignTokens.ColorToken.primaryBurgundy)
                        .frame(minHeight: DesignTokens.Layout.minimumHitTarget, alignment: .leading)
                }
                .accessibilityIdentifier("guide.paper.addNote." + page.id.uuidString)
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

/// The icon surface owns the one gesture-driven press effect.
private struct Prompt11PressBounce<Content: View>: View {
    let reduceMotion: Bool
    @ViewBuilder let content: () -> Content
    var body: some View {
        content().buttonStyle(CutePopButtonStyle(reduceMotion: reduceMotion))
    }
}
