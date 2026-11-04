import XCTest
@testable import Fruitfolio

@MainActor
final class RequiredMADLADLanguageTagTests: XCTestCase {
    func testEachRequiredLanguageUsesItsExactOfficialTokenizerTagOrRemainsExplicitlyUnsupported() throws {
        let root = try XCTUnwrap(Bundle.main.url(forResource: "MADLAD", withExtension: nil))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("tokenizer.json"))) as? [String: Any])
        let model = try XCTUnwrap(json["model"] as? [String: Any])
        let vocab = try XCTUnwrap(model["vocab"] as? [[Any]])
        let tokens = Set(vocab.compactMap { $0.first as? String })
        let unsupported = Set(FruitfolioLanguage.allCases.filter { !tokens.contains("<2\($0.madladTargetCode)>") }.map(\.rawValue))
        XCTAssertEqual(unsupported, Set(["tpi", "ty", "rar", "niu", "gil"]), "A missing tag must never be silently mapped to a different language")
        XCTAssertEqual(FruitfolioLanguage.chineseTraditional.madladTargetCode, "zh_Hant")
        XCTAssertEqual(FruitfolioLanguage.chineseSimplified.madladTargetCode, "zh")
        XCTAssertEqual(FruitfolioLanguage.filipino.madladTargetCode, "fil")
        XCTAssertTrue(tokens.contains("<2zh_Hant>")); XCTAssertTrue(tokens.contains("<2zh>"))
        let attachment = XCTAttachment(string: "Actual bundled official tokenizer inventory. Required selections: \(FruitfolioLanguage.allCases.count). Missing exact targets: \(unsupported.sorted()). Chinese targets remain distinct: zh / zh_Hant. Tag existence is not translation-quality or device verification.")
        attachment.name = "MADLAD_ActualRequiredLanguageTagInventory"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
