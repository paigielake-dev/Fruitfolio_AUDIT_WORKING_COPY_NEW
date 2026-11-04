import Foundation

/// Explicitly supplied history only. Artwork identifies an editable category;
/// its presence never asserts that a condition or testing procedure occurred.
nonisolated enum Prompt27AHealthField: String, Codable, CaseIterable, Identifiable, Sendable {
    case heart, thyroid, liver, stomach, gut, kidneys, skin, bone, muscle
    case dna, chromosome, mitochondrion, cell, cells, rna, protein, receptor, nucleus
    case medication, culture, centrifuge, microscopy, swab, microcentrifugeTube, testTube, pipette, specimen
    case otherLabs, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .heart: return "cardiovascular / heart history"
        case .thyroid: return "thyroid / endocrine history"
        case .liver: return "liver / metabolic history"
        case .stomach: return "stomach / digestive history"
        case .gut: return "gastrointestinal / gut or microbiome history"
        case .kidneys: return "kidney / urinary history"
        case .skin: return "dermatologic / skin history"
        case .bone: return "bone / skeletal history"
        case .muscle: return "muscular / musculoskeletal history"
        case .dna: return "known DNA / genetic information"
        case .chromosome: return "known chromosomal findings"
        case .mitochondrion: return "known mitochondrial findings"
        case .cell: return "other known cellular history"
        case .cells: return "other known cellular / medical history"
        case .rna: return "known RNA-related findings"
        case .protein: return "known protein-related findings"
        case .receptor: return "known receptor-related findings"
        case .nucleus: return "other genetics / genomics information"
        case .medication: return "medication history"
        case .culture: return "cultures / microbiology history"
        case .centrifuge: return "known centrifugation / testing history"
        case .microscopy: return "microscopy history"
        case .swab: return "swab / sample collection history"
        case .microcentrifugeTube: return "known microtube sample history"
        case .testTube: return "known tube sample / testing history"
        case .pipette: return "known sample-transfer / testing history"
        case .specimen: return "specimen collection history"
        case .otherLabs: return "other labs / testing"
        case .other: return "anything else you want Fruitfolio to know?"
        }
    }
    var artwork: String? {
        switch self {
        case .heart: return "body_heart"
        case .thyroid: return "body_thyroid"
        case .liver: return "body_liver"
        case .stomach: return "body_stomach"
        case .gut: return "body_gut_microbiome"
        case .kidneys: return "body_kidneys"
        case .skin: return "body_skin"
        case .bone: return "body_bone"
        case .muscle: return "body_muscle"
        case .dna: return "genetics_dna"
        case .chromosome: return "genetics_chromosome"
        case .mitochondrion: return "genetics_mitochondrion"
        case .cell: return "genetics_cell"
        case .cells: return "genetics_cells"
        case .rna: return "genetics_rna"
        case .protein: return "genetics_protein"
        case .receptor: return "genetics_receptor"
        case .nucleus: return "genetics_nucleus"
        case .medication: return "symptom_medication"
        case .culture: return "lab_agar_plate"
        case .centrifuge: return "lab_centrifuge"
        case .microscopy: return "lab_microscope"
        case .swab: return "lab_collection_swab"
        case .microcentrifugeTube: return "lab_microcentrifuge_tube"
        case .testTube: return "lab_test_tube"
        case .pipette: return "lab_transfer_pipette"
        case .specimen: return "lab_specimen_cup"
        case .otherLabs, .other: return nil
        }
    }
}

nonisolated struct Prompt27AHealthEntry: Codable, Equatable, Sendable {
    enum Status: String, Codable, Sendable { case supplied, preferNotToSay, removed }
    enum Provenance: String, Codable, Sendable { case userReported, clinicianConfirmedAsReportedByUser }
    let text: String
    let status: Status
    let provenance: Provenance
    let lastUpdated: Date
    init(text: String, status: Status = .supplied, clinicianConfirmedByUser: Bool = false, at date: Date = Date()) {
        // Declining/removing a field irreversibly removes its previous medical
        // content. The retained timestamp/status contains no previous value.
        self.text = status == .supplied ? text : ""
        self.status = status
        self.provenance = status == .supplied && clinicianConfirmedByUser ? .clinicianConfirmedAsReportedByUser : .userReported
        self.lastUpdated = date
    }
}
