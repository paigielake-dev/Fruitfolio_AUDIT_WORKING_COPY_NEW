import Foundation
import XCTest
@testable import Fruitfolio

private actor ContactProtectionFixtureRuntime: FruitfolioLocalTranslationRuntime {
    private(set) var inputs: [String] = []
    let dropsProtectedFields: Bool
    init(dropsProtectedFields: Bool = false) { self.dropsProtectedFields = dropsProtectedFields }
    func translate(_ text: String, targetTag: String) async throws -> String {
        inputs.append(text)
        return dropsProtectedFields ? "courriel" : text.replacingOccurrences(of: "email", with: "courriel")
    }
    func releaseResources() async {}
}

final class Prompt1BContactDestinationTests: XCTestCase {
    @MainActor
    func testActualContactLabelsMaskIdentityLiteralsThroughCompactTranslationOwner() async throws {
        let runtime = ContactProtectionFixtureRuntime()
        let owner = FruitfolioControlTranslationState(service: FruitfolioTranslationService(runtime: runtime))
        for destination in Prompt30ContactDestination.allCases {
            let original = destination.label
            let key = FruitfolioControlTranslationState.Key(source: original, language: .french,
                protectedLiterals: destination.protectedLabelLiterals)
            await owner.resolve(key, inferenceAllowed: true)
            let display = owner.presentation(for: key)
            XCTAssertEqual(display.status, .machine)
            for literal in destination.protectedLabelLiterals { XCTAssertTrue(display.text.contains(literal)) }
            XCTAssertEqual(destination.label, original)
        }
        let inputs = await runtime.inputs
        XCTAssertEqual(inputs.count, Prompt30ContactDestination.allCases.count)
        for input in inputs {
            for destination in Prompt30ContactDestination.allCases {
                for literal in destination.protectedLabelLiterals { XCTAssertFalse(input.contains(literal)) }
            }
        }
    }

    @MainActor
    func testDroppedContactIdentityFallsBackToOriginalWithoutDisplayingBrokenLabel() async throws {
        let runtime = ContactProtectionFixtureRuntime(dropsProtectedFields: true)
        let owner = FruitfolioControlTranslationState(service: FruitfolioTranslationService(runtime: runtime))
        let destination = Prompt30ContactDestination.email
        let key = FruitfolioControlTranslationState.Key(source: destination.label, language: .french,
            protectedLiterals: destination.protectedLabelLiterals)
        await owner.resolve(key, inferenceAllowed: true)
        XCTAssertEqual(owner.presentation(for: key).status, .unavailable)
        XCTAssertEqual(owner.presentation(for: key).text, destination.label)
    }

    func testFounderDestinationsRemainExactAndOnlyIntendedExternalActionsExist() {
        let expected: [Prompt30ContactDestination: String] = [
            .instagram: "https://www.instagram.com/fruitsoflife.xo",
            .tiktok: "https://www.tiktok.com/@fruitsoflife.xo?lang=en",
            .email: "mailto:fruitsoflifexo@gmail.com",
            .carrd: "https://fruitsoflifexo.carrd.co"
        ]
        XCTAssertEqual(Set(Prompt30ContactDestination.allCases), Set(expected.keys))
        for destination in Prompt30ContactDestination.allCases {
            XCTAssertEqual(destination.url.absoluteString, expected[destination])
            XCTAssertFalse(destination.label.isEmpty)
            XCTAssertEqual(destination.url.scheme, destination == .email ? "mailto" : "https")
        }
    }
    func testLateCallbacksCannotReopenFailureAfterLeavingOrReplaceNewerRequest() throws {
        var state = Prompt30ContactLinkState()
        XCTAssertNil(state.begin(.email))
        state.appear()
        let old = try XCTUnwrap(state.begin(.instagram))
        let newer = try XCTUnwrap(state.begin(.email))
        state.complete(old, accepted: false)
        XCTAssertNil(state.failedDestination)
        XCTAssertEqual(state.requestID, newer)
        state.complete(newer, accepted: false)
        XCTAssertEqual(state.failedDestination, .email)
        XCTAssertNil(state.begin(.carrd))
        state.dismiss()
        let leaving = try XCTUnwrap(state.begin(.carrd))
        state.disappear()
        state.complete(leaving, accepted: false)
        XCTAssertNil(state.failedDestination)
        state.appear()
        state.complete(leaving, accepted: false)
        XCTAssertNil(state.failedDestination)
        let success = try XCTUnwrap(state.begin(.tiktok))
        state.complete(success, accepted: true)
        XCTAssertNil(state.failedDestination)
        XCTAssertNil(state.requestID)
    }

}
