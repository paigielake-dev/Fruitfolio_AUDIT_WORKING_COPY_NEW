import Foundation

nonisolated enum FruitfolioPersonalHealthGroup: String, CaseIterable, Identifiable, Sendable {
    case body, genetics, laboratories, reproductive, medication, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .body: return "body and medical history"
        case .genetics: return "family, genetic and biological context"
        case .laboratories: return "laboratory and testing history"
        case .reproductive: return "menstrual and reproductive history"
        case .medication: return "medications"
        case .other: return "anything else"
        }
    }
}

nonisolated enum FruitfolioPersonalHealthCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case heart, thyroid, liver, stomach, gut, kidneys, skin, bone, muscle
    case dna, chromosome, mitochondrion, cell, cells, rna, protein, receptor, nucleus
    case cultures, centrifuge, microscopy, swab, microtube, testTube, pipette, specimen, otherLaboratories
    case menstrual, cervical, knownOvulation, fertilityHistory, medications, general
    var id: String { rawValue }
    var group: FruitfolioPersonalHealthGroup {
        switch self {
        case .heart, .thyroid, .liver, .stomach, .gut, .kidneys, .skin, .bone, .muscle: return .body
        case .dna, .chromosome, .mitochondrion, .cell, .cells, .rna, .protein, .receptor, .nucleus: return .genetics
        case .cultures, .centrifuge, .microscopy, .swab, .microtube, .testTube, .pipette, .specimen, .otherLaboratories: return .laboratories
        case .menstrual, .cervical, .knownOvulation, .fertilityHistory: return .reproductive
        case .medications: return .medication
        case .general: return .other
        }
    }
    var title: String {
        switch self {
        case .heart: return "cardiovascular / heart history"
        case .thyroid: return "thyroid / endocrine history"
        case .liver: return "liver / metabolic history"
        case .stomach: return "stomach / digestive history"
        case .gut: return "gastrointestinal / gut / microbiome history"
        case .kidneys: return "kidney / urinary history"
        case .skin: return "skin / dermatologic history"
        case .bone: return "bone / skeletal history"
        case .muscle: return "muscular / musculoskeletal history"
        case .dna: return "known DNA / genetic findings"
        case .chromosome: return "known chromosomal findings"
        case .mitochondrion: return "known mitochondrial findings"
        case .cell: return "other known cellular / medical history"
        case .cells: return "additional cellular / biological history"
        case .rna: return "known RNA-related findings"
        case .protein: return "known protein-related findings"
        case .receptor: return "known receptor-related findings"
        case .nucleus: return "other genetics / genomics information"
        case .cultures: return "cultures / microbiology history"
        case .centrifuge: return "centrifuge-related testing details, if reported"
        case .microscopy: return "microscopy history, if reported"
        case .swab: return "swab / sample collection history"
        case .microtube: return "microtube sample details, if known"
        case .testTube: return "test-tube sample details, if known"
        case .pipette: return "pipette / sample handling details, if reported"
        case .specimen: return "specimen collection history"
        case .otherLaboratories: return "other labs / testing"
        case .menstrual: return "menstrual / uterine history"
        case .cervical: return "cervical history"
        case .knownOvulation: return "ovulation history you choose to report"
        case .fertilityHistory: return "other fertility history"
        case .medications: return "medication history and details"
        case .general: return "anything else you want Fruitfolio to know?"
        }
    }
    var asset: FruitfolioAssetID? {
        switch self {
        case .heart: return .body_heart
        case .thyroid: return .body_thyroid
        case .liver: return .body_liver
        case .stomach: return .body_stomach
        case .gut: return .body_gut_microbiome
        case .kidneys: return .body_kidneys
        case .skin: return .body_skin
        case .bone: return .body_bone
        case .muscle: return .body_muscle
        case .dna: return .genetics_dna
        case .chromosome: return .genetics_chromosome
        case .mitochondrion: return .genetics_mitochondrion
        case .cell: return .genetics_cell
        case .cells: return .genetics_cells
        case .rna: return .genetics_rna
        case .protein: return .genetics_protein
        case .receptor: return .genetics_receptor
        case .nucleus: return .genetics_nucleus
        case .cultures: return .lab_agar_plate
        case .centrifuge: return .lab_centrifuge
        case .microscopy: return .lab_microscope
        case .swab: return .lab_collection_swab
        case .microtube: return .lab_microcentrifuge_tube
        case .testTube: return .lab_test_tube
        case .pipette: return .lab_transfer_pipette
        case .specimen: return .lab_specimen_cup
        case .menstrual: return .menstruation_uterus
        case .cervical: return .fertility_cervix
        case .knownOvulation: return .ovulation_ovary
        case .medications: return .symptom_medication
        case .otherLaboratories, .fertilityHistory, .general: return nil
        }
    }
}

nonisolated enum FruitfolioPersonalHealthStatus: String, Codable, Sendable {
    case provided, preferNotToSay, removed
}
nonisolated enum FruitfolioPersonalHealthProvenance: String, CaseIterable, Codable, Sendable {
    case userProvided, userReportsClinicianConfirmed
    var label: String {
        self == .userProvided ? "user-provided context" : "clinician-confirmed, as you reported"
    }
}
nonisolated struct FruitfolioPersonalHealthEntry: Codable, Equatable, Sendable {
    let category: FruitfolioPersonalHealthCategory
    let status: FruitfolioPersonalHealthStatus
    let text: String?
    let provenance: FruitfolioPersonalHealthProvenance
    let createdAt: Date
    let updatedAt: Date
    var isActive: Bool { status != .removed }
    func validate() throws {
        guard createdAt.timeIntervalSinceReferenceDate.isFinite, updatedAt.timeIntervalSinceReferenceDate.isFinite else {
            throw FruitfolioPersonalHealthError.invalidEntry
        }
        if status == .provided {
            guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, text.count <= 10_000 else {
                throw FruitfolioPersonalHealthError.invalidEntry
            }
        } else if text != nil || provenance != .userProvided { throw FruitfolioPersonalHealthError.invalidEntry }
    }
}
nonisolated enum FruitfolioPersonalHealthError: LocalizedError {
    case invalidEntry
    var errorDescription: String? { "enter only what you choose to share, up to 10,000 characters. skipped, removed and prefer-not-to-say fields contain no medical text." }
}

extension Prompt27AUserReproductiveContext {
    mutating func setPersonalHealth(_ category: FruitfolioPersonalHealthCategory, text: String,
        status: FruitfolioPersonalHealthStatus = .provided,
        provenance: FruitfolioPersonalHealthProvenance = .userProvided, at date: Date = Date()) throws {
        let entry = FruitfolioPersonalHealthEntry(category: category, status: status,
            text: status == .provided ? text : nil, provenance: status == .provided ? provenance : .userProvided,
            createdAt: personalHealthEntries[category.rawValue]?.createdAt ?? date, updatedAt: date)
        try entry.validate()
        personalHealthEntries[category.rawValue] = entry
        personalHealthRevision = UUID()
    }
    func validatePersonalHealthEntries() throws {
        for (key, entry) in personalHealthEntries {
            guard key == entry.category.rawValue else { throw FruitfolioPersonalHealthError.invalidEntry }
            try entry.validate()
        }
    }
}
