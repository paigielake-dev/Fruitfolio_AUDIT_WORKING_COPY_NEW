import Foundation

nonisolated struct Prompt21BodyBiologyEngine: Sendable {
    init() {}

    func presentation(
        for input: Prompt21BodyBiologyInput
    ) -> Prompt21BodyBiologyPresentation {
        switch input.state {
        case .neutral:
            return Prompt21BodyBiologyPresentation(
                state: .neutral,
                title: "your biology, in context",
                body: "as your cycle picture develops, this space can show the biology that may be most relevant.",
                heroAssetName: Prompt21BodyBiologyAsset.ovary,
                heroAccessibilityLabel: "watercolor educational illustration of an ovary, shown as a general biology reference"
            )

        case .follicularEarly:
            return Prompt21BodyBiologyPresentation(
                state: .follicularEarly,
                title: "follicular phase",
                body: "follicles in the ovary are developing, and one may become dominant as ovulation approaches.",
                heroAssetName: Prompt21BodyBiologyAsset.follicularEarly,
                heroAccessibilityLabel: "watercolor educational illustration of an ovary containing developing follicles"
            )

        case .follicularLater:
            return Prompt21BodyBiologyPresentation(
                state: .follicularLater,
                title: "follicular phase",
                body: "follicles in the ovary are developing, and one may become dominant as ovulation approaches.",
                heroAssetName: Prompt21BodyBiologyAsset.follicularLater,
                heroAccessibilityLabel: "watercolor educational illustration of a later follicular-stage ovary with one follicle shown more prominently"
            )

        case .estimatedOvulation:
            return Prompt21BodyBiologyPresentation(
                state: .estimatedOvulation,
                title: "estimated ovulation window",
                body: "around ovulation, a mature follicle may release an oocyte from the ovary.",
                heroAssetName: Prompt21BodyBiologyAsset.ovulationRelease,
                heroAccessibilityLabel: "watercolor educational illustration showing an oocyte being released from a mature ovarian follicle",
                supportingAssetName: Prompt21BodyBiologyAsset.matureOocyte,
                supportingAccessibilityLabel: "watercolor educational illustration of a mature oocyte",
                showsBlueberryUncertainty: true,
                permitsOocyteDrift: true,
                permitsFimbriaeDetail: true
            )

        case .luteal:
            return Prompt21BodyBiologyPresentation(
                state: .luteal,
                title: "luteal phase",
                body: "after ovulation, the emptied follicle becomes the corpus luteum and produces progesterone.",
                heroAssetName: Prompt21BodyBiologyAsset.corpusLuteum,
                heroAccessibilityLabel: "watercolor educational illustration of an ovary highlighting the corpus luteum after ovulation"
            )

        case .menstruation:
            return Prompt21BodyBiologyPresentation(
                state: .menstruation,
                title: "menstruation",
                body: "the uterine lining is shedding, marking the beginning of a new menstrual cycle.",
                heroAssetName: Prompt21BodyBiologyAsset.uterus,
                heroAccessibilityLabel: "watercolor educational illustration of the uterus during menstruation",
                supportingAssetName: Prompt21BodyBiologyAsset.endometrium,
                supportingAccessibilityLabel: "watercolor educational illustration of the uterine lining shedding during menstruation",
                showsPeachDayOne: input.confirmedCycleDayOne
            )
        }
    }
}
