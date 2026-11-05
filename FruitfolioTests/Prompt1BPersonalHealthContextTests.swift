import XCTest
@testable import Fruitfolio

final class Prompt1BPersonalHealthContextTests: XCTestCase {
    func testAllRequiredIllustratedFieldsUseCanonicalSpecificArtwork() {
        let genetics = FruitfolioPersonalHealthCategory.allCases.filter { $0.group == .genetics }.compactMap(\.asset)
        XCTAssertEqual(Set(genetics), Set([.genetics_dna, .genetics_chromosome, .genetics_mitochondrion,
            .genetics_cell, .genetics_cells, .genetics_rna, .genetics_protein, .genetics_receptor, .genetics_nucleus]))
        XCTAssertEqual(FruitfolioPersonalHealthCategory.allCases.filter { $0.group == .body }.count, 9)
        XCTAssertEqual(FruitfolioPersonalHealthCategory.allCases.filter { $0.group == .laboratories }.compactMap(\.asset).count, 8)
        XCTAssertNil(FruitfolioPersonalHealthCategory.otherLaboratories.asset)
        XCTAssertNil(FruitfolioPersonalHealthCategory.general.asset)
        XCTAssertEqual(FruitfolioPersonalHealthCategory.medications.asset, .symptom_medication)
    }
    func testOptionalProfileRoundTripsInExistingContextWithoutInferringBiology() throws {
        var context = Prompt27AUserReproductiveContext(timestamp: Date(timeIntervalSince1970: 0))
        let baselinePolicy = Prompt27AContextPolicyEngine().policy(for: context)
        XCTAssertTrue(context.personalHealthEntries.isEmpty)
        try context.setPersonalHealth(.dna, text: "only the finding i choose to record", at: Date(timeIntervalSince1970: 10))
        try context.setPersonalHealth(.thyroid, text: "what my clinician told me", provenance: .userReportsClinicianConfirmed, at: Date(timeIntervalSince1970: 20))
        XCTAssertEqual(context.personalHealthEntries["thyroid"]?.provenance, .userReportsClinicianConfirmed)
        XCTAssertEqual(context.reproductiveStage.value, .unspecified)
        XCTAssertEqual(Prompt27AContextPolicyEngine().policy(for: context), baselinePolicy)
        let codec = Prompt27AContextCodec()
        XCTAssertEqual(try codec.decode(codec.encode(context)), context)
        let summary = Prompt27AMinimizedAIContext.educationalSummary(from: context)
        XCTAssertFalse(String(describing: summary).contains("only the finding"))
    }
    func testRemovalAndDecliningEraseTextAndInvalidateRevisionWithoutRetainingDetails() throws {
        var context = Prompt27AUserReproductiveContext(timestamp: Date(timeIntervalSince1970: 0))
        try context.setPersonalHealth(.medications, text: "private detail to delete", at: Date(timeIntervalSince1970: 10))
        let revision = context.personalHealthRevision
        try context.setPersonalHealth(.medications, text: "ignored", status: .removed, at: Date(timeIntervalSince1970: 20))
        XCTAssertNotEqual(context.personalHealthRevision, revision)
        XCTAssertNil(context.personalHealthEntries["medications"]?.text)
        XCTAssertEqual(context.personalHealthEntries["medications"]?.createdAt, Date(timeIntervalSince1970: 10))
        XCTAssertEqual(context.personalHealthEntries["medications"]?.updatedAt, Date(timeIntervalSince1970: 20))
        XCTAssertFalse(String(decoding: try Prompt27AContextCodec().encode(context), as: UTF8.self).contains("private detail"))
        try context.setPersonalHealth(.dna, text: "must not persist", status: .preferNotToSay)
        XCTAssertNil(context.personalHealthEntries["dna"]?.text)
        context.clear()
        XCTAssertTrue(context.personalHealthEntries.isEmpty)
        XCTAssertNil(context.personalHealthRevision)
    }
    func testSharedLocalPersistenceRestartsAndRemovalEliminatesMedicalText() throws {
        let suite = "PersonalHealthContextTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt27ALocalContextPersistence(defaults: defaults, key: "context")
        try store.apply { try $0.setPersonalHealth(.general, text: "private context text", at: Date(timeIntervalSince1970: 10)) }
        let restarted = Prompt27ALocalContextPersistence(defaults: defaults, key: "context")
        XCTAssertEqual(restarted.context.personalHealthEntries["general"]?.text, "private context text")
        try restarted.apply { try $0.setPersonalHealth(.general, text: "", status: .removed, at: Date(timeIntervalSince1970: 20)) }
        let reloaded = Prompt27ALocalContextPersistence(defaults: defaults, key: "context")
        XCTAssertNil(reloaded.context.personalHealthEntries["general"]?.text)
        XCTAssertEqual(reloaded.context.personalHealthEntries["general"]?.status, .removed)
        XCTAssertFalse(String(decoding: try XCTUnwrap(defaults.data(forKey: "context")), as: UTF8.self).contains("private context text"))
    }
    func testFailedProfileEditNeverChangesCommittedStateAndLegacyContextDecodesEmpty() throws {
        var context = Prompt27AUserReproductiveContext(timestamp: Date(timeIntervalSince1970: 0))
        let legacy = try Prompt27AContextCodec().encode(context)
        XCTAssertFalse(String(decoding: legacy, as: UTF8.self).contains("personalHealthEntries"))
        XCTAssertTrue(try Prompt27AContextCodec().decode(legacy).personalHealthEntries.isEmpty)
        let before = context
        XCTAssertThrowsError(try context.setPersonalHealth(.general, text: " \n "))
        XCTAssertThrowsError(try context.setPersonalHealth(.general, text: String(repeating: "a", count: 10_001)))
        XCTAssertEqual(context, before)
    }
}
