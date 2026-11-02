import XCTest
import SwiftUI
import UIKit
@testable import Fruitfolio

@MainActor
final class BasketSettlingPresentationRuntimeTests: XCTestCase {
    func testHostedReducedMotionArtworkAcknowledgesItsActualPresentationWithoutDoubleCounting() async throws {
        let suite = "BasketPresentation-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: .init(defaults: defaults),
                                                 researchProvider: Prompt28UnavailableResearchProvider())
        model.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture",
                                         educationalDifficulty: .easy, startingGameLevel: 1)
        model.screen = .catchActive
        model.updateGameplayFieldSize(width: 402, height: 874)
        let geometry = Prompt28BasketCatchGeometry(fieldWidth: 402, fieldHeight: 874)
        let entry = (geometry.mouthY + Prompt28BasketCatchGeometry.starDiameter(fieldWidth: 402) / 2) / 874
        let star = Prompt28FallingStar(x: 0.5, y: entry - 0.002, fallSpeed: 0.1,
                                       horizontalDrift: 0, rotationDegrees: 0)
        model.activeStars = [star]
        model.tick(delta: 0.05, now: Date(timeIntervalSince1970: 100))
        let caught = try XCTUnwrap(model.settledCatches.first { $0.id == star.id })
        XCTAssertFalse(caught.collected)
        let appeared = expectation(description: "Actual hosted artwork appeared")
        let settled = expectation(description: "Actual reduced-motion artwork settled")
        var appearedID: UUID?
        var settledID: UUID?
        let artwork = Prompt28SettledCatchArtwork(caught: caught, reduceMotion: true) { event in
            model.handleCatchPresentation(id: caught.id, event: event)
            switch event {
            case .appeared(let id):
                if appearedID == nil { appearedID = id; appeared.fulfill() }
            case .settled(let id):
                if settledID == nil { settledID = id; settled.fulfill() }
            case .disappeared: break
            }
        }
        let host = UIHostingController(rootView: artwork.frame(width: 80, height: 80))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; model.viewWillDisappear() }
        await fulfillment(of: [appeared, settled], timeout: 3)
        XCTAssertNotNil(appearedID)
        XCTAssertEqual(appearedID, settledID)
        XCTAssertEqual(model.availableStarPasses, 0, "Presentation does not bypass physical settling time")
        model.tick(delta: 0.2, now: Date(timeIntervalSince1970: 100.2))
        XCTAssertEqual(model.availableStarPasses, 1)
        if let id = settledID { model.handleCatchPresentation(id: caught.id, event: .settled(id)) }
        model.tick(delta: 0.2, now: Date(timeIntervalSince1970: 100.4))
        XCTAssertEqual(model.availableStarPasses, 1)
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        let evidence = XCTAttachment(image: image)
        evidence.name = "HostedReducedMotionSettledStar_ActualUIKitView"
        evidence.lifetime = .keepAlways
        add(evidence)
    }
}
