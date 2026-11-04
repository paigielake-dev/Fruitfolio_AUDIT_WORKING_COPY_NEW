import XCTest
@testable import Fruitfolio

final class Prompt05MainHubTests: XCTestCase {
    
    func testHubAuthenticationLabelTracksAuthoritativeState() async {
        await MainActor.run {
            let state = AppState(authenticationState: .signedOut)
            
            XCTAssertEqual(state.hubAccountLabel, "sign in")
            
            state.authenticationState = .signedIn
            
            XCTAssertEqual(state.hubAccountLabel, "account")
        }
    }
    
    func testPrompt04LayoutStillProvidesThreeEqualUtilityColumns() {
        for size in [
            CGSize(width: 375, height: 667),
            CGSize(width: 393, height: 852),
            CGSize(width: 402, height: 874),
            CGSize(width: 440, height: 956)
        ] {
            let metrics = Prompt04BookLayout.metrics(for: size)
            
            XCTAssertEqual(
                metrics.utilityItemWidth * 3,
                metrics.hubContentWidth,
                accuracy: 0.01
            )
            
            XCTAssertGreaterThanOrEqual(
                metrics.hubButtonHeight,
                44
            )
        }
    }
    
    func testHubRouteSetRemainsComplete() {
        let routes: Set<FruitfolioRoute> = [
            .ask,
            .library,
            .guideBuilder,
            .cycle,
            .fruitBasket,
            .faq,
            .contact,
            .settings,
            .account
        ]
        
        XCTAssertEqual(routes.count, 9)
    }
    
}

extension Prompt05MainHubTests {
    @MainActor
    func testTourUsesCanonicalSemanticAnchorsWithoutChangingApprovedDialogue() {
        for step in Prompt07TourStep.allCases {
            XCTAssertEqual(step.semanticMessage.plainText, step.message)
            XCTAssertFalse(step.semanticMessage.spans.isEmpty)
        }
        XCTAssertTrue(Prompt07TourStep.fruitBasket.semanticMessage.spans.contains {
            $0.text == "come fill your fruit basket" && $0.emphasis == .anchorBold
        })
        let guide = Prompt07TourStep.guideBuilder.semanticMessage.spans.filter { $0.emphasis == .anchorBold }.map(\.text)
        XCTAssertEqual(guide, ["chapters", "notes", "study guides", "little handbooks"])
    }

    @MainActor
    func testCanonicalAuthoredAnnotationsPreserveUnicodeAndCombineDeclaredMeaning() {
        let text = "♡ take care: do not skip the next step."
        let document = FruitfolioSemanticDocument.authored(text, annotations: [
            .init(phrase: "do not", emphasis: .anchorBold),
            .init(phrase: "not", emphasis: .spokenItalic),
            .init(phrase: "not", emphasis: .symptomOrPracticalUnderline)
        ])
        XCTAssertEqual(document.plainText, text)
        XCTAssertTrue(document.spans.contains { $0.text == "not" && $0.emphasis == .absoluteBoldItalicUnderline })
        XCTAssertEqual(FruitfolioSemanticDocument.authored(text, annotations: []).plainText, text)
        XCTAssertEqual(FruitfolioSemanticDocument.authored("", annotations: []).spans.count, 0)
    }
}
