import Foundation

nonisolated struct Prompt21BodyBiologyEngine: Sendable {
    init() {}

    func presentation(
        for input: Prompt21BodyBiologyInput,
        contextPolicy: Prompt27AContextPolicyResult = .init()
    ) -> Prompt21BodyBiologyPresentation {
        let adapter = Prompt27AExistingSystemPolicyAdapter(result: contextPolicy)
        // A logged observation remains saved, but does not establish ordinary
        // natural-cycle physiology when the existing context policy restricts it.
        let permitsCycleInterpretation = adapter.showCurrentNextPeriodPrediction
            && adapter.showCurrentFertileWindowPrediction
            && adapter.showCurrentOvulationPrediction
            && adapter.showHormoneRhythmContextMarker
        let effectiveInput = permitsCycleInterpretation ? input : .neutral
        switch effectiveInput.state {
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
                bodySpans: [.init(text: "follicles in the ovary", emphasis: .anchorBold),
                            .init(text: " are developing, and one may become dominant as ovulation approaches.")],
                heroAssetName: Prompt21BodyBiologyAsset.follicularEarly,
                heroAccessibilityLabel: "watercolor educational illustration of an ovary containing developing follicles"
            )

        case .follicularLater:
            return Prompt21BodyBiologyPresentation(
                state: .follicularLater,
                title: "follicular phase",
                body: "follicles in the ovary are developing, and one may become dominant as ovulation approaches.",
                bodySpans: [.init(text: "follicles in the ovary", emphasis: .anchorBold),
                            .init(text: " are developing, and one may become dominant as ovulation approaches.")],
                heroAssetName: Prompt21BodyBiologyAsset.follicularLater,
                heroAccessibilityLabel: "watercolor educational illustration of a later follicular-stage ovary with one follicle shown more prominently"
            )

        case .estimatedOvulation:
            return Prompt21BodyBiologyPresentation(
                state: .estimatedOvulation,
                title: "estimated ovulation window",
                body: "around ovulation, a mature follicle may release an oocyte from the ovary.",
                bodySpans: [.init(text: "around ovulation, a mature follicle "),
                            .init(text: "may release an oocyte", emphasis: .anchorBold), .init(text: " from the ovary.")],
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
                bodySpans: [.init(text: "after ovulation, the emptied follicle becomes the "),
                            .init(text: "corpus luteum", emphasis: .anchorBold), .init(text: " and produces "),
                            .init(text: "progesterone", emphasis: .anchorBold), .init(text: ".")],
                heroAssetName: Prompt21BodyBiologyAsset.corpusLuteum,
                heroAccessibilityLabel: "watercolor educational illustration of an ovary highlighting the corpus luteum after ovulation"
            )

        case .menstruation:
            return Prompt21BodyBiologyPresentation(
                state: .menstruation,
                title: "menstruation",
                body: "the uterine lining is shedding, marking the beginning of a new menstrual cycle.",
                bodySpans: [.init(text: "the "), .init(text: "uterine lining", emphasis: .anchorBold),
                            .init(text: " is shedding, marking the beginning of a new menstrual cycle.")],
                heroAssetName: Prompt21BodyBiologyAsset.uterus,
                heroAccessibilityLabel: "watercolor educational illustration of the uterus during menstruation",
                supportingAssetName: Prompt21BodyBiologyAsset.endometrium,
                supportingAccessibilityLabel: "watercolor educational illustration of the uterine lining shedding during menstruation",
                showsPeachDayOne: effectiveInput.confirmedCycleDayOne
            )
        }
    }
}
