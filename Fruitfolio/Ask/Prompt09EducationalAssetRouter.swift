import Foundation

struct EducationalAssetDescriptor: Hashable, Sendable {
    let assetID: FruitfolioAssetID
    let topicTags: Set<String>
    let conceptTags: Set<String>
    let accessibilityDescription: String
    let requiresResearchSupport: Bool
}

/// Prompt 09 routing rule:
/// evidence/support is resolved first; only then may a matching educational asset appear.
struct EducationalAssetRouter: Sendable {
    static let shared = EducationalAssetRouter()

    let descriptors: [EducationalAssetDescriptor]

    init(descriptors: [EducationalAssetDescriptor] = EducationalAssetRouter.canonicalDescriptors) {
        self.descriptors = descriptors
    }

    func assets(
        for conceptTags: Set<String>,
        support: AskKnowledgeSupport,
        maximumCount: Int = 2
    ) -> [EducationalAssetDescriptor] {
        guard support != .genuinelyNovel, !conceptTags.isEmpty, maximumCount > 0 else {
            return []
        }

        let normalizedInput = Set(conceptTags.map(Self.normalize))

        return descriptors
            .compactMap { descriptor -> (EducationalAssetDescriptor, Int)? in
                guard descriptor.requiresResearchSupport else { return nil }

                let topics = Set(descriptor.topicTags.map(Self.normalize))
                let concepts = Set(descriptor.conceptTags.map(Self.normalize))
                let topicMatches = topics.intersection(normalizedInput)
                let conceptMatches = concepts.intersection(normalizedInput)

                // Founder rule: an overlapping word is not enough. A visual is
                // eligible only when the answer tags identify the educational
                // topic AND substantially identify the complete concept taught
                // by the artwork. Default is therefore no artwork.
                // Require both a supported topic and a specific educational
                // concept. A second concept tag is not mandatory.
                guard !topicMatches.isEmpty,
                      !conceptMatches.isEmpty else {
                    return nil
                }

                let score = topicMatches.count * 2 + conceptMatches.count * 3
                return (descriptor, score)
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.accessibilityDescription < rhs.0.accessibilityDescription
            }
            .prefix(maximumCount)
            .map(\.0)
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static let canonicalDescriptors: [EducationalAssetDescriptor] = [
        .init(assetID: .female_pelvic_anatomy_spatial_comparison, topicTags: ["pelvic anatomy", "reproductive anatomy"], conceptTags: ["uterus", "ovary", "pelvis"], accessibilityDescription: "Educational illustration of female pelvic anatomy spatial relationships", requiresResearchSupport: true),
        .init(assetID: .period_fennel_tea, topicTags: ["period", "menstruation"], conceptTags: ["fennel", "tea"], accessibilityDescription: "Educational illustration of fennel tea in a period-support context", requiresResearchSupport: true),
        .init(assetID: .period_green_tea, topicTags: ["period", "menstruation"], conceptTags: ["green tea", "tea"], accessibilityDescription: "Educational illustration of green tea in a period-support context", requiresResearchSupport: true),
        .init(assetID: .makeup_presentation_face_product_placement, topicTags: ["makeup", "presentation"], conceptTags: ["face", "product placement"], accessibilityDescription: "Educational face makeup product-placement guide", requiresResearchSupport: true),
        .init(assetID: .makeup_presentation_nose_shape_contour, topicTags: ["makeup", "presentation"], conceptTags: ["nose", "contour"], accessibilityDescription: "Educational nose-shape contour guide", requiresResearchSupport: true),
        .init(assetID: .pcos_support_juice, topicTags: ["PCOS", "nutrition"], conceptTags: ["juice", "food"], accessibilityDescription: "Educational PCOS support juice illustration", requiresResearchSupport: true),
        .init(assetID: .breastfeeding_nutrition_food_servings, topicTags: ["breastfeeding", "nutrition"], conceptTags: ["food", "servings"], accessibilityDescription: "Educational breastfeeding nutrition food-servings guide", requiresResearchSupport: true),
        .init(assetID: .makeup_presentation_lip_shape_guide, topicTags: ["makeup", "presentation"], conceptTags: ["lips", "lip shape"], accessibilityDescription: "Educational lip-shape presentation guide", requiresResearchSupport: true),
        .init(assetID: .pregnancy_berry_spinach_smoothie, topicTags: ["pregnancy", "nutrition"], conceptTags: ["smoothie", "berries", "spinach"], accessibilityDescription: "Educational pregnancy berry and spinach smoothie illustration", requiresResearchSupport: true),
        .init(assetID: .period_cinnamon_tea, topicTags: ["period", "menstruation"], conceptTags: ["cinnamon", "tea"], accessibilityDescription: "Educational cinnamon tea illustration in a period-support context", requiresResearchSupport: true),
        .init(assetID: .fertility_support_juice, topicTags: ["fertility", "nutrition"], conceptTags: ["juice", "food"], accessibilityDescription: "Educational fertility support juice illustration", requiresResearchSupport: true),
        .init(assetID: .pregnancy_back_pain_seated_posture, topicTags: ["pregnancy", "back pain"], conceptTags: ["posture", "seated posture"], accessibilityDescription: "Educational seated-posture guide for pregnancy back discomfort", requiresResearchSupport: true),
        .init(assetID: .sustenance_for_period_foods_to_avoid, topicTags: ["period", "menstruation", "nutrition"], conceptTags: ["foods to avoid", "food"], accessibilityDescription: "Educational period nutrition guide showing foods to avoid", requiresResearchSupport: true),
        .init(assetID: .period_spearmint_tea, topicTags: ["period", "menstruation"], conceptTags: ["spearmint", "tea"], accessibilityDescription: "Educational spearmint tea illustration in a period-support context", requiresResearchSupport: true),
        .init(assetID: .key_vitamins_nutrients_food_wheel, topicTags: ["nutrition", "vitamins", "nutrients"], conceptTags: ["food", "vitamins", "nutrients"], accessibilityDescription: "Educational food wheel for key vitamins and nutrients", requiresResearchSupport: true),
        .init(assetID: .ovarian_cycle_follicle_development_stages, topicTags: ["ovulation", "ovarian cycle"], conceptTags: ["follicle", "follicle development", "oocyte"], accessibilityDescription: "Educational follicle-development stages across the ovarian cycle", requiresResearchSupport: true),
        .init(assetID: .pelvic_floor_friendly_yoga_pilates_exercises, topicTags: ["pelvic floor", "exercise"], conceptTags: ["yoga", "pilates", "movement"], accessibilityDescription: "Educational pelvic-floor-friendly yoga and Pilates exercise guide", requiresResearchSupport: true),
        .init(assetID: .makeup_presentation_face_shape_contour, topicTags: ["makeup", "presentation"], conceptTags: ["face shape", "contour"], accessibilityDescription: "Educational face-shape contour guide", requiresResearchSupport: true),
        .init(assetID: .endometriosis_support_juice, topicTags: ["endometriosis", "nutrition"], conceptTags: ["juice", "food"], accessibilityDescription: "Educational endometriosis support juice illustration", requiresResearchSupport: true),
        .init(assetID: .period_marjoram_tea, topicTags: ["period", "menstruation"], conceptTags: ["marjoram", "tea"], accessibilityDescription: "Educational marjoram tea illustration in a period-support context", requiresResearchSupport: true),
        .init(assetID: .pregnancy_discomforts_round_ligament_pain, topicTags: ["pregnancy", "pregnancy discomforts"], conceptTags: ["round ligament pain", "ligament"], accessibilityDescription: "Educational pregnancy round-ligament discomfort illustration", requiresResearchSupport: true),
        .init(assetID: .sustenance_for_period_foods_to_eat, topicTags: ["period", "menstruation", "nutrition"], conceptTags: ["foods to eat", "food"], accessibilityDescription: "Educational period nutrition guide showing foods to eat", requiresResearchSupport: true),
        .init(assetID: .period_rose_hip_tea, topicTags: ["period", "menstruation"], conceptTags: ["rose hip", "tea"], accessibilityDescription: "Educational rose hip tea illustration in a period-support context", requiresResearchSupport: true),
        .init(assetID: .menopause_transition_juice, topicTags: ["menopause", "nutrition"], conceptTags: ["juice", "food"], accessibilityDescription: "Educational menopause-transition juice illustration", requiresResearchSupport: true),
        .init(assetID: .menstrual_cramps_prostaglandin_mechanism, topicTags: ["period", "menstruation", "menstrual cramps"], conceptTags: ["prostaglandins", "cramps", "uterine contractions"], accessibilityDescription: "Educational diagram of the prostaglandin mechanism involved in menstrual cramps", requiresResearchSupport: true),
        .init(assetID: .fluid_balance_facial_roller_lymphatic_drainage_guide, topicTags: ["fluid balance", "facial care"], conceptTags: ["facial roller", "lymphatic drainage"], accessibilityDescription: "Educational facial roller and lymphatic drainage guide", requiresResearchSupport: true),
        .init(assetID: .pregnancy_exercises_back_pain_movement_guide, topicTags: ["pregnancy", "back pain", "exercise"], conceptTags: ["movement", "exercise", "back pain"], accessibilityDescription: "Educational pregnancy movement guide for back discomfort", requiresResearchSupport: true),
        .init(assetID: .period_support_juice, topicTags: ["period", "menstruation", "nutrition"], conceptTags: ["juice", "food"], accessibilityDescription: "Educational period support juice illustration", requiresResearchSupport: true),
        .init(assetID: .pelvic_floor_health_kegel_positions, topicTags: ["pelvic floor", "exercise"], conceptTags: ["Kegels", "pelvic floor exercises"], accessibilityDescription: "Educational pelvic-floor Kegel position guide", requiresResearchSupport: true),
        .init(assetID: .uterine_ovarian_cycle_phase_diagram, topicTags: ["menstrual cycle", "ovarian cycle"], conceptTags: ["uterine cycle", "cycle phases", "ovulation"], accessibilityDescription: "Educational uterine and ovarian cycle phase diagram", requiresResearchSupport: true),
        .init(assetID: .hormone_balance_juice, topicTags: ["hormones", "nutrition"], conceptTags: ["juice", "food"], accessibilityDescription: "Educational hormone-related nutrition juice illustration", requiresResearchSupport: true),
        .init(assetID: .uti_support_juice, topicTags: ["UTI", "urinary health", "nutrition"], conceptTags: ["juice", "food"], accessibilityDescription: "Educational UTI support juice illustration", requiresResearchSupport: true),
        .init(assetID: .pregnancy_strawberry_pineapple_smoothie, topicTags: ["pregnancy", "nutrition"], conceptTags: ["smoothie", "strawberry", "pineapple"], accessibilityDescription: "Educational pregnancy strawberry and pineapple smoothie illustration", requiresResearchSupport: true),
        .init(assetID: .sexual_health_bacterial_viral_stis, topicTags: ["sexual health", "STIs"], conceptTags: ["bacterial STI", "viral STI"], accessibilityDescription: "Educational comparison of bacterial and viral sexually transmitted infections", requiresResearchSupport: true),
        .init(assetID: .pregnancy_nutrition_food_servings, topicTags: ["pregnancy", "nutrition"], conceptTags: ["food", "servings"], accessibilityDescription: "Educational pregnancy nutrition food-servings guide", requiresResearchSupport: true),
        .init(assetID: .period_ginger_tea, topicTags: ["period", "menstruation"], conceptTags: ["ginger", "tea"], accessibilityDescription: "Educational ginger tea illustration in a period-support context", requiresResearchSupport: true),
        .init(assetID: .pregnancy_tropical_greens_smoothie, topicTags: ["pregnancy", "nutrition"], conceptTags: ["smoothie", "greens"], accessibilityDescription: "Educational pregnancy tropical greens smoothie illustration", requiresResearchSupport: true),
        .init(assetID: .weight_loss_strength_training_exercise_guide, topicTags: ["exercise", "strength training"], conceptTags: ["strength training", "movement"], accessibilityDescription: "Educational strength-training exercise guide", requiresResearchSupport: true),
        .init(assetID: .doctor_advocacy_prepare_for_visit, topicTags: ["doctor advocacy", "health literacy"], conceptTags: ["appointment", "prepare for visit", "questions"], accessibilityDescription: "Educational guide for preparing for a medical visit and self-advocacy", requiresResearchSupport: true),
        .init(assetID: .debloating_juice, topicTags: ["bloating", "nutrition"], conceptTags: ["juice", "food"], accessibilityDescription: "Educational debloating juice illustration", requiresResearchSupport: true),
        .init(assetID: .period_chamomile_tea, topicTags: ["period", "menstruation"], conceptTags: ["chamomile", "tea"], accessibilityDescription: "Educational chamomile tea illustration in a period-support context", requiresResearchSupport: true),
        .init(assetID: .fluid_balance_gua_sha_facial_massage_guide, topicTags: ["fluid balance", "facial care"], conceptTags: ["gua sha", "facial massage"], accessibilityDescription: "Educational gua sha facial massage guide", requiresResearchSupport: true),
        .init(assetID: .breastfeeding_help_proper_latch, topicTags: ["breastfeeding"], conceptTags: ["latch", "feeding"], accessibilityDescription: "Educational breastfeeding proper-latch guide", requiresResearchSupport: true),
        .init(assetID: .makeup_presentation_eye_shape_guide, topicTags: ["makeup", "presentation"], conceptTags: ["eye shape", "eyes"], accessibilityDescription: "Educational eye-shape presentation guide", requiresResearchSupport: true)
    ]
}
