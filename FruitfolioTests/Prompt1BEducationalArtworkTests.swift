import XCTest
@testable import Fruitfolio

final class Prompt1BEducationalArtworkTests: XCTestCase {
    func testMatchingWordAloneAndIncompleteEvidenceNeverOfferScientificArt() {
        let router = EducationalAssetRouter.shared
        XCTAssertTrue(router.assets(for: ["ovulation"], support: .supported).isEmpty)
        XCTAssertTrue(router.assets(for: ["ovulation", "follicle"], support: .partiallySupported).isEmpty)
        XCTAssertTrue(router.assets(for: ["ovulation", "follicle"], support: .genuinelyNovel).isEmpty)
    }
    func testOrdinaryAskCannotProduceAnAnatomyCollageEvenWhenSeveralVisualsMatch() {
        let tags: Set<String> = ["ovulation", "follicle", "pelvic anatomy", "uterus", "nutrition", "period", "tea", "fennel"]
        let router = EducationalAssetRouter.shared
        XCTAssertEqual(router.assets(for: tags, support: .supported, maximumCount: 100).count, 1)
        XCTAssertTrue(router.assets(for: tags, support: .supported, maximumCount: 0).isEmpty)
    }
}
