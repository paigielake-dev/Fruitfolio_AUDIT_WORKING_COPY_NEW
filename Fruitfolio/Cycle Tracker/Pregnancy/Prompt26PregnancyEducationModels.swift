import Foundation

// MARK: - Canonical Phase 26 educational state

enum Prompt26PregnancyEducationKind: String, Codable, CaseIterable, Sendable {
    case educational
}

enum Prompt26PregnancyTopicID: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case testing
    case earlyDevelopment = "early_development"
    case fetalDevelopment = "fetal_development"
    case placenta
    case umbilicalCord = "umbilical_cord"
    case ultrasound
    case prenatalVitamins = "prenatal_vitamins"

    var id: String { rawValue }
}

enum Prompt26PregnancyAsset: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case placenta = "pregnancy_placenta"
    case prenatalVitamins = "pregnancy_prenatal_vitamins"
    case test = "pregnancy_test"
    case earlyEmbryo = "pregnancy_early_embryo"
    case stage03 = "pregnancy_stage_03"
    case stage02 = "pregnancy_stage_02"
    case stage01 = "pregnancy_stage_01"
    case stage04 = "pregnancy_stage_04"
    case umbilicalCord = "pregnancy_umbilical_cord"
    case ultrasoundProbe = "pregnancy_ultrasound_probe"

    var id: String { rawValue }
    var imageName: String { rawValue }
    var physicalFilename: String { rawValue + ".png" }
}

struct Prompt26PregnancyEducationTopic: Identifiable, Equatable, Sendable {
    let id: Prompt26PregnancyTopicID
    let title: String
    let subtitle: String
    let heroAsset: Prompt26PregnancyAsset
    let shortContentID: String
    let sectionIDs: [String]
    let sourceIDs: [String]
    let relatedTopicIDs: [Prompt26PregnancyTopicID]
    let altText: String
    let hotspotIDs: [String]
    let kind: Prompt26PregnancyEducationKind

    init(
        id: Prompt26PregnancyTopicID,
        title: String,
        subtitle: String,
        heroAsset: Prompt26PregnancyAsset,
        shortContentID: String,
        sectionIDs: [String],
        sourceIDs: [String] = [],
        relatedTopicIDs: [Prompt26PregnancyTopicID] = [],
        altText: String,
        hotspotIDs: [String] = [],
        kind: Prompt26PregnancyEducationKind = .educational
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.heroAsset = heroAsset
        self.shortContentID = shortContentID
        self.sectionIDs = sectionIDs
        self.sourceIDs = sourceIDs
        self.relatedTopicIDs = relatedTopicIDs
        self.altText = altText
        self.hotspotIDs = hotspotIDs
        self.kind = kind
    }
}

struct Prompt26DevelopmentReferencePeriod: Identifiable, Equatable, Sendable {
    let id: String
    let displayRange: String
    let illustrationAsset: Prompt26PregnancyAsset
    let contentID: String
    let sourceIDs: [String]
    let altText: String

    init(
        id: String,
        displayRange: String,
        illustrationAsset: Prompt26PregnancyAsset,
        contentID: String,
        sourceIDs: [String] = [],
        altText: String
    ) {
        self.id = id
        self.displayRange = displayRange
        self.illustrationAsset = illustrationAsset
        self.contentID = contentID
        self.sourceIDs = sourceIDs
        self.altText = altText
    }
}

struct Prompt26PregnancyHotspot: Identifiable, Equatable, Sendable {
    let id: String
    let illustrationAsset: Prompt26PregnancyAsset
    let normalizedX: Double
    let normalizedY: Double
    let label: String
    let contentID: String
    let sourceIDs: [String]

    init(
        id: String,
        illustrationAsset: Prompt26PregnancyAsset,
        normalizedX: Double,
        normalizedY: Double,
        label: String,
        contentID: String,
        sourceIDs: [String]
    ) {
        self.id = id
        self.illustrationAsset = illustrationAsset
        self.normalizedX = min(max(normalizedX, 0), 1)
        self.normalizedY = min(max(normalizedY, 0), 1)
        self.label = label
        self.contentID = contentID
        self.sourceIDs = sourceIDs
    }
}

struct Prompt26ApprovedSection: Identifiable, Equatable, Sendable {
    let id: String
    let heading: String
    let body: String
    let sourceIDs: [String]

    init(id: String, heading: String, body: String, sourceIDs: [String]) {
        self.id = id
        self.heading = heading
        self.body = body
        self.sourceIDs = sourceIDs
    }
}

struct Prompt26ApprovedContent: Equatable, Sendable {
    let contentID: String
    let title: String
    let summary: String
    let sections: [Prompt26ApprovedSection]
    let sourceIDs: [String]

    init(
        contentID: String,
        title: String,
        summary: String,
        sections: [Prompt26ApprovedSection],
        sourceIDs: [String]
    ) {
        self.contentID = contentID
        self.title = title
        self.summary = summary
        self.sections = sections
        self.sourceIDs = sourceIDs
    }
}

struct Prompt26SavedEducationEntry: Equatable, Sendable {
    let topicID: Prompt26PregnancyTopicID
    let title: String
    let contentID: String
    let sourceIDs: [String]
    let kind: Prompt26PregnancyEducationKind

    init(
        topicID: Prompt26PregnancyTopicID,
        title: String,
        contentID: String,
        sourceIDs: [String]
    ) {
        self.topicID = topicID
        self.title = title
        self.contentID = contentID
        self.sourceIDs = sourceIDs
        self.kind = .educational
    }
}

struct Prompt26PregnancyAskIndexEntry: Equatable, Sendable {
    let topicID: Prompt26PregnancyTopicID
    let contentIDs: [String]
    let conceptTags: [String]
    let requiresResearchSupport: Bool

    init(
        topicID: Prompt26PregnancyTopicID,
        contentIDs: [String],
        conceptTags: [String],
        requiresResearchSupport: Bool = true
    ) {
        self.topicID = topicID
        self.contentIDs = contentIDs
        self.conceptTags = conceptTags
        self.requiresResearchSupport = requiresResearchSupport
    }
}
