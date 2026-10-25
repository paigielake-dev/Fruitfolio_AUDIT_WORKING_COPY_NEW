import Foundation

enum Prompt26PregnancyEducationCatalog {
    static let topics: [Prompt26PregnancyEducationTopic] = [
        .init(
            id: .testing,
            title: "pregnancy testing",
            subtitle: "Understanding pregnancy tests, timing, and results.",
            heroAsset: .test,
            shortContentID: "pregnancy.testing.core",
            sectionIDs: [
                "pregnancy.testing.hcg",
                "pregnancy.testing.timing",
                "pregnancy.testing.results",
                "pregnancy.testing.limitations"
            ],
            relatedTopicIDs: [.earlyDevelopment, .prenatalVitamins],
            altText: "Watercolor educational illustration of a neutral home pregnancy test."
        ),
        .init(
            id: .earlyDevelopment,
            title: "early development",
            subtitle: "A sourced reference to early pregnancy development.",
            heroAsset: .earlyEmbryo,
            shortContentID: "pregnancy.early_development.core",
            sectionIDs: [
                "pregnancy.early_development.implantation",
                "pregnancy.early_development.terminology",
                "pregnancy.early_development.transitions"
            ],
            relatedTopicIDs: [.fetalDevelopment, .placenta],
            altText: "Watercolor scientific illustration representing early embryonic development."
        ),
        .init(
            id: .fetalDevelopment,
            title: "fetal development",
            subtitle: "General developmental reference periods, not a personalized timeline.",
            heroAsset: .stage01,
            shortContentID: "pregnancy.fetal_development.core",
            sectionIDs: [
                "pregnancy.fetal_development.variability",
                "pregnancy.fetal_development.scale",
                "pregnancy.fetal_development.terminology"
            ],
            relatedTopicIDs: [.earlyDevelopment, .placenta, .umbilicalCord],
            altText: "Watercolor scientific illustration representing a fetal development reference period."
        ),
        .init(
            id: .placenta,
            title: "placenta",
            subtitle: "A sourced reference to placental biology.",
            heroAsset: .placenta,
            shortContentID: "pregnancy.placenta.core",
            sectionIDs: [
                "pregnancy.placenta.development",
                "pregnancy.placenta.anatomy",
                "pregnancy.placenta.exchange",
                "pregnancy.placenta.hormones",
                "pregnancy.placenta.circulation"
            ],
            relatedTopicIDs: [.umbilicalCord, .fetalDevelopment],
            altText: "Watercolor anatomical illustration of the placenta with the attached umbilical cord."
        ),
        .init(
            id: .umbilicalCord,
            title: "umbilical cord",
            subtitle: "A sourced reference to cord anatomy and circulation.",
            heroAsset: .umbilicalCord,
            shortContentID: "pregnancy.umbilical_cord.core",
            sectionIDs: [
                "pregnancy.umbilical_cord.anatomy",
                "pregnancy.umbilical_cord.vessels",
                "pregnancy.umbilical_cord.whartons_jelly",
                "pregnancy.umbilical_cord.circulation"
            ],
            relatedTopicIDs: [.placenta, .fetalDevelopment],
            altText: "Watercolor scientific illustration of the umbilical cord."
        ),
        .init(
            id: .ultrasound,
            title: "ultrasound",
            subtitle: "How ultrasound is used as medical imaging.",
            heroAsset: .ultrasoundProbe,
            shortContentID: "pregnancy.ultrasound.core",
            sectionIDs: [
                "pregnancy.ultrasound.sound_waves",
                "pregnancy.ultrasound.approaches",
                "pregnancy.ultrasound.limitations",
                "pregnancy.ultrasound.professional_role"
            ],
            relatedTopicIDs: [.earlyDevelopment, .fetalDevelopment],
            altText: "Watercolor educational illustration of an ultrasound probe."
        ),
        .init(
            id: .prenatalVitamins,
            title: "prenatal vitamins",
            subtitle: "A sourced reference to prenatal nutrition concepts.",
            heroAsset: .prenatalVitamins,
            shortContentID: "pregnancy.prenatal_vitamins.core",
            sectionIDs: [
                "pregnancy.prenatal_vitamins.folate",
                "pregnancy.prenatal_vitamins.nutrients",
                "pregnancy.prenatal_vitamins.dosing",
                "pregnancy.prenatal_vitamins.safety",
                "pregnancy.prenatal_vitamins.preconception"
            ],
            relatedTopicIDs: [.testing, .earlyDevelopment],
            altText: "Watercolor educational still life representing prenatal vitamin supplementation."
        )
    ]

    static let fetalReferencePeriods: [Prompt26DevelopmentReferencePeriod] = [
        .init(
            id: "reference_01",
            displayRange: "development reference 1",
            illustrationAsset: .stage01,
            contentID: "pregnancy.fetal_development.reference_01",
            altText: "Watercolor scientific illustration for fetal development reference 1."
        ),
        .init(
            id: "reference_02",
            displayRange: "development reference 2",
            illustrationAsset: .stage02,
            contentID: "pregnancy.fetal_development.reference_02",
            altText: "Watercolor scientific illustration for fetal development reference 2."
        ),
        .init(
            id: "reference_03",
            displayRange: "development reference 3",
            illustrationAsset: .stage03,
            contentID: "pregnancy.fetal_development.reference_03",
            altText: "Watercolor scientific illustration for fetal development reference 3."
        ),
        .init(
            id: "reference_04",
            displayRange: "development reference 4",
            illustrationAsset: .stage04,
            contentID: "pregnancy.fetal_development.reference_04",
            altText: "Watercolor scientific illustration for fetal development reference 4."
        )
    ]

    static let askIndex: [Prompt26PregnancyAskIndexEntry] = [
        .init(topicID: .testing, contentIDs: ["pregnancy.testing.core"], conceptTags: ["pregnancy test", "hcg", "urine test", "blood test"]),
        .init(topicID: .earlyDevelopment, contentIDs: ["pregnancy.early_development.core"], conceptTags: ["implantation", "early embryonic development"]),
        .init(topicID: .fetalDevelopment, contentIDs: ["pregnancy.fetal_development.core"], conceptTags: ["fetal development", "developmental terminology"]),
        .init(topicID: .placenta, contentIDs: ["pregnancy.placenta.core"], conceptTags: ["placenta", "maternal fetal interface", "placental exchange"]),
        .init(topicID: .umbilicalCord, contentIDs: ["pregnancy.umbilical_cord.core"], conceptTags: ["umbilical cord", "wharton's jelly", "umbilical vessels"]),
        .init(topicID: .ultrasound, contentIDs: ["pregnancy.ultrasound.core"], conceptTags: ["ultrasound", "sound wave imaging"]),
        .init(topicID: .prenatalVitamins, contentIDs: ["pregnancy.prenatal_vitamins.core"], conceptTags: ["prenatal vitamins", "folic acid", "folate", "iron", "iodine", "vitamin d", "choline", "dha"])
    ]

    static func topic(_ id: Prompt26PregnancyTopicID) -> Prompt26PregnancyEducationTopic {
        guard let topic = topics.first(where: { $0.id == id }) else {
            preconditionFailure("Prompt 26 catalog is missing canonical topic: \(id.rawValue)")
        }
        return topic
    }

    static var reachableAssets: Set<Prompt26PregnancyAsset> {
        let topicAssets = topics.map(\.heroAsset)
        let referenceAssets = fetalReferencePeriods.map(\.illustrationAsset)
        return Set(topicAssets + referenceAssets)
    }
}
