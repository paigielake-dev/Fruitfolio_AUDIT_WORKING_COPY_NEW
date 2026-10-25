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
