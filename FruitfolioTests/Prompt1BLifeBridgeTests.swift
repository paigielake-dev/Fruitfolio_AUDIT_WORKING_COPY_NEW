import XCTest
@testable import Fruitfolio

/// Nonclinical publisher contract fixture, not official organization content.
private actor Prompt1BPublisherSynthesisProbe: FruitfolioLanguageModel {
    private(set) var calls = 0
    func availability() async -> FruitfolioLanguageModelAvailability { .packageNotLinked }
    func generateDraft(question: String, evidence: FruitfolioEvidencePacket) async throws -> FruitfolioGeneratedDraft {
        calls += 1
        throw FruitfolioLanguageModelError.unavailable(.packageNotLinked)
    }
}

/// Controlled identifier-loss probe, not MADLAD language-quality evidence.
private actor Prompt1BPublisherQueryRuntime: FruitfolioLocalTranslationRuntime {
    private(set) var sawProtectedName = false
    func translate(_ text: String, targetTag: String) async throws -> String {
        sawProtectedName = text.contains("FFPROTECT_")
        return text.replacingOccurrences(of: "comment contacter", with: "how to contact")
            .replacingOccurrences(of: "LifeBridge", with: "unprotected-name-changed")
    }
    func releaseResources() async {}
}

final class Prompt1BLifeBridgeTests: XCTestCase {
    private func snapshot(id: String = "official", url: URL? = FruitfolioLifeBridgeInformation.officialURL,
        title: String = "nonclinical validation fixture", version: String = "fixture",
        text: String = "nonclinical URL validation only", retrieved: Date = Date(timeIntervalSince1970: 1_000),
        reviewed: Date = Date(timeIntervalSince1970: 2_000)) throws -> FruitfolioLifeBridgeSnapshot {
        .init(id: id, title: title, sourceURL: try XCTUnwrap(url), retrievedAt: retrieved,
            reviewedAt: reviewed, version: version, approvedText: text)
    }
    private func content(official: FruitfolioLifeBridgeSnapshot? = nil,
        founder: FruitfolioLifeBridgeSnapshot? = nil, application: URL? = nil) throws -> FruitfolioLifeBridgeContent {
        .init(snapshots: [try official ?? snapshot(),
            try founder ?? snapshot(id: "founder", url: FruitfolioLifeBridgeInformation.founderURL)],
            officialApplicationURL: application, relationshipDisclosure: nil)
    }
    private func writeResource<Content: Encodable>(_ content: Content) throws -> (directory: URL, file: URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Fruitfolio.Publishers." + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        do {
            let file = directory.appendingPathComponent("LifeBridgeApprovedContent.json")
            let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(content).write(to: file)
            return (directory, file)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    func testGenericBrandRouteKeepsMedicalAndLifeBridgeQuestionsInTheirOwnPipelines() {
        for question in ["what is Fruitfolio?", "who created Fruitfolio?", "what products does FruitsofLife.xo offer?",
                         "where can I download Fruitfolio?", "how can I contact FruitsofLife.xo?",
                         "what educational content does FruitsofLife.xo offer?",
                         "tell me about FruitsofLife.xo announcements", "FruitsofLife.xo platform information"] {
            XCTAssertTrue(FruitfolioBrandInformation.isInformationQuestion(question), question)
        }
        for question in ["does Fruitfolio treat infertility?", "FruitsofLife.xo progesterone products",
                         "Fruitfolio medical advice", "Fruitfolio LifeBridge eligibility", "what is FruitfolioBank?",
                         "what products treat PCOS?", "FruitsofLife.xo.xyz products"] {
            XCTAssertFalse(FruitfolioBrandInformation.isInformationQuestion(question), question)
        }
    }

    func testBrandResourceRequiresExactAccountReviewDatesUniqueIDsAndDeclaredScope() throws {
        let valid = try snapshot(id: "brand", url: FruitfolioLifeBridgeInformation.founderInstagramURL)
        XCTAssertTrue(FruitfolioBrandContent(scope: .brandAndProductInformation, snapshots: [valid]).validate())
        XCTAssertFalse(FruitfolioBrandContent(scope: .brandAndProductInformation, snapshots: []).validate())
        XCTAssertFalse(FruitfolioBrandContent(scope: .brandAndProductInformation, snapshots: [valid, valid]).validate())
        for text in ["https://instagram.com/fruitsoflife.xo/", "https://www.instagram.com/another-account/",
                     "https://www.instagram.com/fruitsoflife.xo/extra", "https://www.instagram.com/p/unknown-author/",
                     "https://www.instagram.com/fruitsoflife.xo/?redirect=other", "https://www.instagram.com/fruitsoflife.xo/#other",
                     "https://user@www.instagram.com/fruitsoflife.xo/", "https://www.instagram.com:444/fruitsoflife.xo/"] {
            let invalid = try snapshot(url: URL(string: text))
            XCTAssertFalse(FruitfolioBrandContent(scope: .brandAndProductInformation, snapshots: [invalid]).validate(), text)
        }
        for invalid in [try snapshot(url: FruitfolioLifeBridgeInformation.founderInstagramURL, version: ""),
                        try snapshot(url: FruitfolioLifeBridgeInformation.founderInstagramURL, text: " \n"),
                        try snapshot(url: FruitfolioLifeBridgeInformation.founderInstagramURL,
                            retrieved: Date(timeIntervalSince1970: 3_000), reviewed: Date(timeIntervalSince1970: 2_000)),
                        try snapshot(url: FruitfolioLifeBridgeInformation.founderInstagramURL,
                            reviewed: Date.distantFuture)] {
            XCTAssertFalse(FruitfolioBrandContent(scope: .brandAndProductInformation, snapshots: [invalid]).validate())
        }
        let encoded = try JSONEncoder().encode(FruitfolioBrandContent(scope: .brandAndProductInformation, snapshots: [valid]))
        let wrongScope = String(decoding: encoded, as: UTF8.self)
            .replacingOccurrences(of: "brandAndProductInformation", with: "independentScientificEvidence")
        XCTAssertThrowsError(try JSONDecoder().decode(FruitfolioBrandContent.self, from: Data(wrongScope.utf8)))
        XCTAssertFalse(try content(official: valid).validate(), "Instagram must not replace either mandatory LifeBridge source")
    }

    @MainActor
    func testActualBrandResourceFeedsSourceSpecificAskWithoutScientificOrGenerativeSubstitution() async throws {
        let account = FruitfolioLifeBridgeInformation.founderInstagramURL
        let product = try snapshot(id: "product", url: account, title: "products fixture",
            text: "nonclinical product fixture *exact original*. all qualifications remain.")
        let contact = try snapshot(id: "contact", url: account, title: "contact fixture",
            text: "nonclinical contact fixture.")
        let resource = try writeResource(FruitfolioBrandContent(scope: .brandAndProductInformation, snapshots: [contact, product]))
        defer { try? FileManager.default.removeItem(at: resource.directory) }
        let store = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/unavailable/research.json"),
            brandResourceURL: resource.file)
        let model = Prompt1BPublisherSynthesisProbe()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: store, languageModel: model)
        let first = try await engine.answer(question: "what products does FruitsofLife.xo offer?", conversation: [])
        XCTAssertEqual(first.answerPath, .publisherInformation)
        XCTAssertEqual(first.support, .partiallySupported)
        XCTAssertEqual(first.sourceIDs, ["fruitsoflife-brand:product"])
        XCTAssertEqual(first.originalQuestion, "what products does FruitsofLife.xo offer?")
        XCTAssertTrue(first.answerText.contains(FruitfolioSemanticMarkup.markdown([.init(text: product.approvedText)])))
        XCTAssertTrue(first.answerText.contains("not independent scientific evidence"))
        let record = try XCTUnwrap(first.sources.first)
        XCTAssertEqual(record.urlString, account?.absoluteString)
        XCTAssertEqual(record.contentVersion, product.version)
        XCTAssertNil(record.doi)
        XCTAssertNil(record.publicationData)
        XCTAssertTrue(record.sourceText?.contains(product.reviewedAt.ISO8601Format()) == true)
        XCTAssertNotNil(Prompt09SaveSourceVersions.validated(first.sources))
        let second = try await engine.answer(question: "how can I contact FruitsofLife.xo?", conversation: [])
        XCTAssertEqual(second.sourceIDs, ["fruitsoflife-brand:contact"])
        XCTAssertNotEqual(first.id, second.id, "Only static reviewed content is cached, never a prior answer")
        XCTAssertNil(engine.lastDiagnostics)
        let calls = await model.calls
        XCTAssertEqual(calls, 0)
    }

    @MainActor
    func testMissingOrInvalidBrandSnapshotReturnsExplicitUnavailableWithoutInventedFacts() async throws {
        let resource = try writeResource(FruitfolioBrandContent(scope: .brandAndProductInformation,
            snapshots: [try snapshot(url: FruitfolioLifeBridgeInformation.officialURL)]))
        defer { try? FileManager.default.removeItem(at: resource.directory) }
        let model = Prompt1BPublisherSynthesisProbe()
        let store = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/unavailable/research.json"),
            brandResourceURL: resource.file)
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: store, languageModel: model)
        let answer = try await engine.answer(question: "what is Fruitfolio?", conversation: [])
        XCTAssertEqual(answer.answerPath, .unavailableContent)
        XCTAssertEqual(answer.knowledgeBaseVersion, FruitfolioBrandInformation.awaitingStatus)
        XCTAssertTrue(answer.sources.isEmpty)
        XCTAssertTrue(answer.sourceIDs.isEmpty)
        let calls = await model.calls
        XCTAssertEqual(calls, 0)
        XCTAssertNil(FruitfolioBrandInformation.load(at: try XCTUnwrap(FruitfolioLifeBridgeInformation.founderInstagramURL)),
            "A source URL must never initiate a publisher fetch")
    }

    func testPublisherIntentCannotHijackUnrelatedOrMedicalResearchQuestions() {
        for text in ["what is LifeBridge?", "tell me about LifeBridge Surrogacy", "how do I contact life bridge?",
                     "LifeBridge eligibility", "LifeBridge application", "LifeBridge referral information"] {
            XCTAssertTrue(FruitfolioLifeBridgeInformation.isInformationQuestion(text), text)
        }
        for text in ["what is progesterone?", "how does surrogacy affect hormones?",
                     "how does LifeBridge progesterone affect temperature?", "what is LifeBridgeBank?"] {
            XCTAssertFalse(FruitfolioLifeBridgeInformation.isInformationQuestion(text), text)
        }
    }

    func testSourceSpecificQuotesPreserveWholeTextAttributionPriorityAndReviewFlags() throws {
        let official = try snapshot(title: "official application fixture", text: "application fixture text *retained*.\nall original qualifications stay here.")
        let founder = try snapshot(id: "founder", url: FruitfolioLifeBridgeInformation.founderURL,
            title: "founder context fixture", text: "nonclinical founder context only.")
        let data = FruitfolioLifeBridgeContent(snapshots: [founder, official], officialApplicationURL: nil,
            relationshipDisclosure: "nonclinical disclosure fixture", sourceDiscrepancies: ["nonclinical discrepancy fixture"])
        let answer = try XCTUnwrap(data.informationalAnswer(originalQuestion: "original question", query: "LifeBridge application"))
        XCTAssertEqual(data.orderedSnapshots.map(\.id), [official.id, founder.id])
        XCTAssertEqual(answer.answerPath, .publisherInformation)
        XCTAssertEqual(answer.support, .partiallySupported)
        XCTAssertTrue(answer.answerText.contains(FruitfolioSemanticMarkup.markdown([.init(text: official.approvedText)])))
        XCTAssertTrue(answer.answerText.contains(founder.approvedText))
        XCTAssertTrue(answer.answerText.contains("nonclinical disclosure fixture"))
        XCTAssertTrue(answer.answerText.contains("source differences flagged for founder review"))
        XCTAssertTrue(answer.answerText.contains("nonclinical discrepancy fixture"))
        XCTAssertEqual(answer.sourceIDs, ["lifebridge-publisher:official", "lifebridge-publisher:founder"])
        let versions = try XCTUnwrap(Prompt09SaveSourceVersions.validated(answer.sources))
        XCTAssertEqual(versions["lifebridge-publisher:official"], official.version)
        XCTAssertEqual(versions["lifebridge-publisher:founder"], founder.version)
        for (record, snapshot) in zip(answer.sources, [official, founder]) {
            XCTAssertEqual(record.title, snapshot.title)
            XCTAssertEqual(record.urlString, snapshot.sourceURL.absoluteString)
            XCTAssertEqual(record.contentVersion, snapshot.version)
            XCTAssertNil(record.doi)
            XCTAssertNil(record.publicationData, "Review date must not masquerade as publication date")
            XCTAssertTrue(record.sourceText?.contains(snapshot.reviewedAt.ISO8601Format()) == true)
        }
    }

    @MainActor
    func testActualActorOwnedResourceFeedsAskWithoutResearchModelAndCachesNoQuestionAnswer() async throws {
        let officialContact = try snapshot(id: "contact", title: "contact fixture", text: "contact fixture paragraph.")
        let officialApplication = try snapshot(id: "application", title: "application fixture", text: "application fixture paragraph.")
        let founder = try snapshot(id: "founder", url: FruitfolioLifeBridgeInformation.founderURL, text: "founder context fixture.")
        let content = FruitfolioLifeBridgeContent(snapshots: [founder, officialContact, officialApplication],
            officialApplicationURL: nil, relationshipDisclosure: nil)
        let resource = try writeResource(content)
        defer { try? FileManager.default.removeItem(at: resource.directory) }
        let store = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/unavailable/research.json"),
            lifeBridgeResourceURL: resource.file)
        let model = Prompt1BPublisherSynthesisProbe()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: store, languageModel: model)
        let first = try await engine.answer(question: "LifeBridge application", conversation: [])
        XCTAssertEqual(first.answerPath, .publisherInformation)
        XCTAssertEqual(first.sources.first?.title, officialApplication.title)
        XCTAssertEqual(first.originalQuestion, "LifeBridge application")
        XCTAssertNil(engine.lastDiagnostics)
        try FileManager.default.removeItem(at: resource.file)
        let second = try await engine.answer(question: "LifeBridge contact", conversation: [])
        XCTAssertEqual(second.answerPath, .publisherInformation)
        XCTAssertEqual(second.sources.first?.title, officialContact.title)
        XCTAssertEqual(second.originalQuestion, "LifeBridge contact")
        let calls = await model.calls
        XCTAssertEqual(calls, 0, "Publisher quotations must not become model-memory organization claims")
    }

    @MainActor
    func testLocalizedPublisherQuestionUsesProtectedOriginalNameBeforeScopedLookup() async throws {
        let resource = try writeResource(content())
        defer { try? FileManager.default.removeItem(at: resource.directory) }
        let store = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/unavailable/research.json"),
            lifeBridgeResourceURL: resource.file)
        let runtime = Prompt1BPublisherQueryRuntime()
        let model = Prompt1BPublisherSynthesisProbe()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: store, languageModel: model,
            translationService: .init(runtime: runtime))
        let original = "comment contacter LifeBridge ?"
        let answer = try await engine.answer(question: original, conversation: [], trackerContext: nil,
            userContext: nil, inputLanguage: .french, translationInferenceAllowed: true, progress: nil)
        XCTAssertEqual(answer.answerPath, .publisherInformation)
        XCTAssertEqual(answer.originalQuestion, original)
        let protected = await runtime.sawProtectedName
        XCTAssertTrue(protected, "A changed publisher identifier must not redirect the source lookup")
        let calls = await model.calls
        XCTAssertEqual(calls, 0)
    }

    @MainActor
    func testSingleWebsiteResourceStillCannotProduceAnOrganizationAnswer() async throws {
        let incomplete = FruitfolioLifeBridgeContent(snapshots: [try snapshot()], officialApplicationURL: nil, relationshipDisclosure: nil)
        let resource = try writeResource(incomplete)
        defer { try? FileManager.default.removeItem(at: resource.directory) }
        let store = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/unavailable/research.json"),
            lifeBridgeResourceURL: resource.file)
        let model = Prompt1BPublisherSynthesisProbe()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: store, languageModel: model)
        let answer = try await engine.answer(question: "LifeBridge contact", conversation: [])
        XCTAssertEqual(answer.answerPath, .unavailableContent)
        XCTAssertTrue(answer.sourceIDs.isEmpty)
        let calls = await model.calls
        XCTAssertEqual(calls, 0)
    }

    @MainActor
    func testMedicalQuestionMentioningLifeBridgeStillSearchesActualScientificLibrary() async throws {
        let resource = try writeResource(content())
        defer { try? FileManager.default.removeItem(at: resource.directory) }
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json"))
        let store = FruitfolioResearchPackageStore(resourceURL: url, lifeBridgeResourceURL: resource.file)
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: store, languageModel: Prompt1BPublisherSynthesisProbe())
        let answer = try await engine.answer(question: "how does LifeBridge progesterone affect temperature?", conversation: [])
        XCTAssertNotEqual(answer.answerPath, .publisherInformation)
        XCTAssertGreaterThan(engine.lastDiagnostics?.noteCount ?? 0, 0)
        XCTAssertTrue(answer.sourceIDs.allSatisfy { !$0.hasPrefix("lifebridge-publisher:") })
    }

    func testStrictLocalLoaderRejectsNetworkAndOversizedOtherwiseValidResource() throws {
        XCTAssertNil(FruitfolioLifeBridgeInformation.load(at: try XCTUnwrap(URL(string: "https://lifebridgesurrogacy.com/source.json"))))
        XCTAssertNil(FruitfolioLifeBridgeInformation.load(at: try XCTUnwrap(URL(string: "file://not-local.invalid/source.json"))))
        let resource = try writeResource(content())
        defer { try? FileManager.default.removeItem(at: resource.directory) }
        XCTAssertNotNil(FruitfolioLifeBridgeInformation.load(at: resource.file))
        var data = try Data(contentsOf: resource.file)
        data.append(Data(repeating: 0x20, count: 8 * 1024 * 1024 + 1 - data.count))
        try data.write(to: resource.file)
        XCTAssertNil(FruitfolioLifeBridgeInformation.load(at: resource.file), "Reject oversize; do not silently truncate accepted publisher content")
    }

    func testExactProperNamesRetainCaseAcrossAdjacentWritingSystemsWithoutInventedAliases() {
        XCTAssertEqual(FruitfolioLifeBridgeInformation.protectedNames(in: "LifeBridgeについて fruitsoflife.xo وFruitfolio"),
                       ["LifeBridge", "fruitsoflife.xo", "Fruitfolio"])
        XCTAssertEqual(FruitfolioLifeBridgeInformation.protectedNames(in: "LifeBridge LifeBridge LifeBridge"), ["LifeBridge"])
        XCTAssertTrue(FruitfolioLifeBridgeInformation.protectedNames(in: "LifeBridgeBank unrelatedFruitfolioSuffix").isEmpty)
    }

    func testSourceURLsRejectCredentialsAndNonOfficialServicePorts() throws {
        XCTAssertTrue(try content().validate())
        for raw in ["https://user:secret@lifebridgesurrogacy.com/", "https://lifebridgesurrogacy.com:8443/"] {
            XCTAssertFalse(try content(official: snapshot(url: URL(string: raw))).validate(), raw)
        }
        for raw in ["https://user@fruitsoflifexo.carrd.co/", "https://fruitsoflifexo.carrd.co:8443/"] {
            XCTAssertFalse(try content(founder: snapshot(id: "founder", url: URL(string: raw))).validate(), raw)
        }
    }
    func testApplicationURLRetainsApprovedReferenceButRejectsCredentialsAndOtherServices() throws {
        let allowed = try XCTUnwrap(URL(string: "https://lifebridgesurrogacy.com:443/apply?ref=approved-fixture#form"))
        let approved = try content(application: allowed)
        XCTAssertTrue(approved.validate())
        XCTAssertEqual(approved.officialApplicationURL, allowed)
        for raw in ["https://user:secret@lifebridgesurrogacy.com/apply", "https://lifebridgesurrogacy.com:8443/apply",
            "http://lifebridgesurrogacy.com/apply", "https://lifebridgesurrogacy.com.evil.example/apply"] {
            XCTAssertFalse(try content(application: URL(string: raw)).validate(), raw)
        }
    }
    func testBlankReviewMetadataAndNonfiniteDatesCannotMasqueradeAsReviewedContent() throws {
        let invalid = [try snapshot(id: " \n"), try snapshot(title: " \t"), try snapshot(version: "\n"),
            try snapshot(text: " \n"), try snapshot(retrieved: Date(timeIntervalSinceReferenceDate: -.infinity)),
            try snapshot(retrieved: Date(timeIntervalSinceReferenceDate: -.infinity), reviewed: Date(timeIntervalSinceReferenceDate: -.infinity))]
        for source in invalid { XCTAssertFalse(try content(official: source).validate()) }
        XCTAssertFalse(try content().validate(now: Date(timeIntervalSinceReferenceDate: .infinity)))
    }

    func testDiscoveryAndFounderSpecifiedDestinationsAreExact() {
        XCTAssertTrue(FruitfolioLifeBridgeInformation.isDiscoverable(for: "tell me about surrogacy support"))
        XCTAssertTrue(FruitfolioLifeBridgeInformation.isOrganizationQuestion("LifeBridge eligibility"))
        XCTAssertFalse(FruitfolioLifeBridgeInformation.isOrganizationQuestion("what is progesterone?"))
        XCTAssertEqual(FruitfolioLifeBridgeInformation.officialURL?.absoluteString, "https://lifebridgesurrogacy.com/")
        XCTAssertEqual(FruitfolioLifeBridgeInformation.founderURL?.absoluteString, "https://fruitsoflifexo.carrd.co/")
        XCTAssertEqual(FruitfolioLifeBridgeInformation.founderInstagramURL?.absoluteString, "https://www.instagram.com/fruitsoflife.xo/")
    }
    func testInstagramCannotReplaceRequiredLifeBridgeAndCarrdSnapshots() throws {
        let instagram = try snapshot(id: "instagram", url: FruitfolioLifeBridgeInformation.founderInstagramURL)
        for missing in [FruitfolioLifeBridgeContent(snapshots: [instagram], officialApplicationURL: nil, relationshipDisclosure: nil),
                        FruitfolioLifeBridgeContent(snapshots: [try snapshot(), instagram], officialApplicationURL: nil, relationshipDisclosure: nil),
                        FruitfolioLifeBridgeContent(snapshots: [try snapshot(id: "founder", url: FruitfolioLifeBridgeInformation.founderURL), instagram], officialApplicationURL: nil, relationshipDisclosure: nil)] {
            XCTAssertFalse(missing.validate(), "A first-party brand account is not either mandatory organization/source snapshot")
        }
    }

    func testOneWebsiteCannotStandInForBothRequiredSources() throws {
        let date = Date(timeIntervalSince1970: 1_000)
        let source = FruitfolioLifeBridgeSnapshot(id: "official", title: "fixture", sourceURL: try XCTUnwrap(FruitfolioLifeBridgeInformation.officialURL),
            retrievedAt: date, reviewedAt: date, version: "fixture", approvedText: "fixture only")
        XCTAssertFalse(FruitfolioLifeBridgeContent(snapshots: [source], officialApplicationURL: nil, relationshipDisclosure: nil).validate())
    }
}
