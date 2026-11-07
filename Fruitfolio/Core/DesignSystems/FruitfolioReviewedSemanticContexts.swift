import Foundation

/// Reviewed formatting metadata, never another factual source or a keyword styler.
/// An entry applies only to its complete exact original passage. Text changes
/// require a new editorial review; source approval remains the caller's gate.
enum FruitfolioReviewedSemanticContexts {
    struct Passage: Sendable {
        let noteID: String
        let originalText: String
        let rationale: String
        let spans: [FruitfolioSemanticSpan]
    }
    static let passages: [Passage] = [
        .init(noteID: "note_ca00d1045d9609459ec60f03", originalText: "fruit-based sweet ideas\nfruit-based snacks can satisfy sweetness while adding fiber, fluid, and micronutrients.\napple slices with peanut butter.\nbanana with almond butter.\nGreek yogurt with berries.\ncottage cheese with pineapple.\norange slices with pistachios.\ngrapes with cheese.\npear with walnuts.\nstrawberries with yogurt dip.\nfrozen blueberries with milk.\nmango with lime.",
              rationale: "This passage is a list of concrete snack foods; retain their complete names, including modifiers. Introductory prose and connecting words stay plain.", spans: [
            .init(text: "fruit-based sweet ideas\nfruit-based snacks can satisfy sweetness while adding fiber, fluid, and micronutrients.\n", emphasis: .plain),
            .init(text: "apple slices", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "peanut butter", emphasis: .anchorBold),
            .init(text: ".\n", emphasis: .plain),
            .init(text: "banana", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "almond butter", emphasis: .anchorBold),
            .init(text: ".\n", emphasis: .plain),
            .init(text: "Greek yogurt", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "berries", emphasis: .anchorBold),
            .init(text: ".\n", emphasis: .plain),
            .init(text: "cottage cheese", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "pineapple", emphasis: .anchorBold),
            .init(text: ".\n", emphasis: .plain),
            .init(text: "orange slices", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "pistachios", emphasis: .anchorBold),
            .init(text: ".\n", emphasis: .plain),
            .init(text: "grapes", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "cheese", emphasis: .anchorBold),
            .init(text: ".\n", emphasis: .plain),
            .init(text: "pear", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "walnuts", emphasis: .anchorBold),
            .init(text: ".\n", emphasis: .plain),
            .init(text: "strawberries", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "yogurt dip", emphasis: .anchorBold),
            .init(text: ".\n", emphasis: .plain),
            .init(text: "frozen blueberries", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "milk", emphasis: .anchorBold),
            .init(text: ".\n", emphasis: .plain),
            .init(text: "mango", emphasis: .anchorBold),
            .init(text: " with ", emphasis: .plain),
            .init(text: "lime", emphasis: .anchorBold),
            .init(text: ".", emphasis: .plain),
        ]),
        .init(noteID: "note_5252619bd571aff2f8c82363", originalText: "AMH does not tell the exact number of eggs left.\nAMH does not tell exactly when menopause will happen.\nAMH does not guarantee IVF success.\na normal AMH does not rule out infertility.\na low AMH does not mean pregnancy is impossible.\na high AMH does not mean fertility is guaranteed.\nAMH does not evaluate sperm.\nAMH does not evaluate fallopian tubes.\nAMH does not evaluate uterine problems.\nAMH does not confirm ovulation.\nAMH does not replace a full fertility workup when someone is trying to conceive.\nAMH and people not seeking fertility care",
              rationale: "Identify the hormone once and emphasize two important limitations as qualifying clues; no playful vocal stress or diagnostic interpretation.", spans: [
            .init(text: "AMH", emphasis: .anchorBold),
            .init(text: " does not tell the exact number of eggs left.\nAMH does not tell exactly when menopause will happen.\nAMH ", emphasis: .plain),
            .init(text: "does not guarantee IVF success", emphasis: .symptomOrPracticalUnderline),
            .init(text: ".\na normal AMH does not rule out infertility.\na low AMH does not mean pregnancy is impossible.\na high AMH does not mean fertility is guaranteed.\nAMH does not evaluate sperm.\nAMH does not evaluate fallopian tubes.\nAMH does not evaluate uterine problems.\nAMH ", emphasis: .plain),
            .init(text: "does not confirm ovulation", emphasis: .symptomOrPracticalUnderline),
            .init(text: ".\nAMH does not replace a full fertility workup when someone is trying to conceive.\nAMH and people not seeking fertility care", emphasis: .plain),
        ]),
        .init(noteID: "note_2e7c8247dbc9b52b4fabc7d8", originalText: "•     these include:\n•     androgens.\n•     estrogens, especially estradiol.\n•     these hormones support follicular development through local signaling.\ngranulosa cell differentiation\n•     fsh stimulation helps granulosa cells separate into 2 compartments:\n•     cumulus cells.\n•     mural granulosa cells.\n•     the cumulus compartment surrounds and supports the oocyte.\n•     this differentiation helps the arrested oocyte continue meiosis i.\n•     after continuing meiosis i, the oocyte becomes arrested again in metaphase ii.\novulation",
              rationale: "The named hormone class/specific member and its local biological role are informational anchors in this oogenesis passage.", spans: [
            .init(text: "•     these include:\n•     androgens.\n•     ", emphasis: .plain),
            .init(text: "estrogens, especially estradiol", emphasis: .anchorBold),
            .init(text: ".\n•     these hormones support ", emphasis: .plain),
            .init(text: "follicular development", emphasis: .anchorBold),
            .init(text: " through local signaling.\ngranulosa cell differentiation\n•     fsh stimulation helps granulosa cells separate into 2 compartments:\n•     cumulus cells.\n•     mural granulosa cells.\n•     the cumulus compartment surrounds and supports the oocyte.\n•     this differentiation helps the arrested oocyte continue meiosis i.\n•     after continuing meiosis i, the oocyte becomes arrested again in metaphase ii.\novulation", emphasis: .plain),
        ]),
        .init(noteID: "note_a920c0ef910e05ec5208a9d7", originalText: "•      ovulation happens after a surge of lh, or luteinizing hormone.\n•      the lh surge causes the follicular wall to rupture.\n•      the cumulus-oocyte complex is released.\n•      this released oocyte is arrested in metaphase ii.\n•      after ovulation, granulosa and theca cells contribute to the formation of luteal\ncells.\n•      luteal cells secrete hormones, especially progesterone, and also estradiol.\ncompletion of meiosis ii\n•    the mature oocyte does not complete meiosis ii unless fertilization happens.\n•    fertilization by a sperm cell triggers completion of meiosis ii.\n•    after fertilization, the oocyte and sperm genetic material combine to form a\nzygote.",
              rationale: "The named LH signal and follicular-rupture mechanism are central biological anchors; preserve the complete surrounding oogenesis context.", spans: [
            .init(text: "•      ovulation happens after a surge of ", emphasis: .plain),
            .init(text: "lh, or luteinizing hormone", emphasis: .anchorBold),
            .init(text: ".\n•      the lh surge causes the ", emphasis: .plain),
            .init(text: "follicular wall to rupture", emphasis: .anchorBold),
            .init(text: ".\n•      the cumulus-oocyte complex is released.\n•      this released oocyte is arrested in metaphase ii.\n•      after ovulation, granulosa and theca cells contribute to the formation of luteal\ncells.\n•      luteal cells secrete hormones, especially progesterone, and also estradiol.\ncompletion of meiosis ii\n•    the mature oocyte does not complete meiosis ii unless fertilization happens.\n•    fertilization by a sperm cell triggers completion of meiosis ii.\n•    after fertilization, the oocyte and sperm genetic material combine to form a\nzygote.", emphasis: .plain),
        ]),
        .init(noteID: "note_638477e8908b98b245971d44", originalText: "what AMH is\nanti-müllerian hormone, or AMH, is a hormone made by cells inside ovarian follicles.\novarian follicles are small fluid-filled sacs in the ovaries.\nfollicles contain immature eggs.\nAMH levels are linked with the number of growing follicles in the ovaries.\nAMH is used as one marker of ovarian reserve.\novarian reserve means the number of eggs remaining in the ovaries.\nAMH is measured with a blood test.\nAMH does not fluctuate as much across the menstrual cycle as some other reproductive hormones.\nbecause AMH is relatively stable, it can often be checked on many cycle days.\nAMH naturally changes with age.\nAMH tends to rise during adolescence and young adulthood.",
              rationale: "The complete AMH name is the defining anchor. Its role as one marker and the bounded comparison of cycle variation are qualifiers, not diagnostic conclusions.", spans: [
            .init(text: "what AMH is\n", emphasis: .plain),
            .init(text: "anti-müllerian hormone, or AMH", emphasis: .anchorBold),
            .init(text: ", is a hormone made by cells inside ovarian follicles.\novarian follicles are small fluid-filled sacs in the ovaries.\nfollicles contain immature eggs.\nAMH levels are linked with the number of growing follicles in the ovaries.\nAMH is used as ", emphasis: .plain),
            .init(text: "one marker of ovarian reserve", emphasis: .symptomOrPracticalUnderline),
            .init(text: ".\novarian reserve means the number of eggs remaining in the ovaries.\nAMH is measured with a blood test.\nAMH ", emphasis: .plain),
            .init(text: "does not fluctuate as much across the menstrual cycle", emphasis: .symptomOrPracticalUnderline),
            .init(text: " as some other reproductive hormones.\nbecause AMH is relatively stable, it can often be checked on many cycle days.\nAMH naturally changes with age.\nAMH tends to rise during adolescence and young adulthood.", emphasis: .plain),
        ]),
    ]
}
