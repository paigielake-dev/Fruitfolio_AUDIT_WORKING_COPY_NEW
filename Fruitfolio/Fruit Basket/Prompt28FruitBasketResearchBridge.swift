import Foundation

/// Prompt 28 consumes approved, already-retrieved educational records through this
/// narrow contract. It never falls back to web search or model memory.
protocol Prompt28ResearchProviding: Sendable {
    func question(
        topic: String,
        normalizedTopic: String,
        difficulty: Prompt28EducationalDifficulty,
        excludingQuestionIDs: Set<String>
    ) async throws -> Prompt28Question
}

enum Prompt28ResearchError: LocalizedError, Equatable, Sendable {
    case providerUnavailable
    case unsupportedTopic
    case topicExhausted
    case invalidQuestion
    case sourceValidationFailed

    var errorDescription: String? {
        switch self {
        case .providerUnavailable:
            return "the approved FruitsofLife.xo research library is not connected to Fruit Basket in this build yet."
        case .unsupportedTopic:
            return "i don’t have enough approved research o…14204 tokens truncated…026-11-02.txt:84",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift",
        "Fruitfolio/Core/Assets/AudioManager.swift"
      ],
      "testsPerformed": [],
      "supportingEvidence": [],
      "actualResult": "Collision/movement integration added; Apple execution pending. Approved named water-entry, water-movement and branch-impact assets are absent; audible quality and natural exit remain unverified."
    },
    {
      "requirementID": "SUP-20261102-03-001",
      "requirement": "Actual registered fruit catches.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:104",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift",
        "FruitfolioTests/FruitBasketGroundedResearchTests.swift"
      ],
      "testsPerformed": [],
      "supportingEvidence": [],
      "actualResult": "Actual existing collections and original explanation/source snapshots are now persisted per completed attempt. New frame/restart/research-replacement tests await Apple execution. Bite-sized fact, full visual, scientific-meaning and complete end-to-end acceptance remain unverified."
    },
    {
      "requirementID": "SUP-20261102-03-002",
      "requirement": "Actual stars collected.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:105",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift",
        "FruitfolioTests/FruitBasketGroundedResearchTests.swift"
      ],
      "testsPerformed": [],
      "supportingEvidence": [],
      "actualResult": "Actual existing collections and original explanation/source snapshots are now persisted per completed attempt. New frame/restart/research-replacement tests await Apple execution. Bite-sized fact, full visual, scientific-meaning and complete end-to-end acceptance remain unverified."
    },
    {
      "requirementID": "SUP-20261102-03-003",
      "requirement": "Star passes used.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:106",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift",
        "FruitfolioTests/FruitBasketGroundedResearchTests.swift"
      ],
      "testsPerformed": [],
      "supportingEvidence": [],
      "actualResult": "Actual existing collections and original explanation/source snapshots are now persisted per completed attempt. New frame/restart/research-replacement tests await Apple execution. Bite-sized fact, full visual, scientific-meaning and complete end-to-end acceptance remain unverified."
    },
    {
      "requirementID": "SUP-20261102-03-004",
      "requirement": "Final round score.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:107",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift",
        "FruitfolioTests/FruitBasketGroundedResearchTests.swift"
      ],
      "testsPerformed": [],
      "supportingEvidence": [],
      "actualResult": "Actual existing collections and original explanation/source snapshots are now persisted per completed attempt. New frame/restart/research-replacement tests await Apple execution. Bite-sized fact, full visual, scientific-meaning and complete end-to-end acceptance remain unverified."
    },
    {
      "requirementID": "SUP-20261102-03-005",
      "requirement": "Applicable rewards and consequences.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:108",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift",
        "FruitfolioTests/FruitBasketGroundedResearchTests.swift"
      ],
      "testsPerformed": [],
      "supportingEvidence": [],
      "actualResult": "Actual existing collections and original explanation/source snapshots are now persisted per completed attempt. New frame/restart/research-replacement tests await Apple execution. Bite-sized fact, full visual, scientific-meaning and complete end-to-end acceptance remain unverified."
    },
    {
      "requirementID": "SUP-20261102-03-006",
      "requirement": "Personal-best celebration where appropriate.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:109",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift",
        "FruitfolioTests/FruitBasketGroundedResearchTests.swift"
      ],
      "testsPerformed": [],
      "supportingEvidence": [],
      "actualResult": "Actual existing collections and original explanation/source snapshots are now persisted per completed attempt. New frame/restart/research-replacement tests await Apple execution. Bite-sized fact, full visual, scientific-meaning and complete end-to-end acceptance remain unverified."
    },
    {
      "requirementID": "SUP-20261102-03-007",
      "requirement": "Bite-sized educational facts associated with the round\u2019s questions.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:110",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift",
        "FruitfolioTests/FruitBasketGroundedResearchTests.swift"
      ],
      "testsPerformed": [],
      "supportingEvidence": [],
      "actualResult": "Actual existing collections and original explanation/source snapshots are now persisted per completed attempt. New frame/restart/research-replacement tests await Apple execution. Bite-sized fact, full visual, scientific-meaning and complete end-to-end acceptance remain unverified."
    },
    {
      "requirementID": "SUP-20261102-03-008",
      "requirement": "Supporting research citations where appropriate.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:111",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift",
        "FruitfolioTests/FruitBasketGroundedResearchTests.swift"
      ],
      "testsPerformed": [],
      "supportingEvidence": [],
      "actualResult": "Actual existing collections and original explanation/source snapshots are now persisted per completed attempt. New frame/restart/research-replacement tests await Apple execution. Bite-sized fact, full visual, scientific-meaning and complete end-to-end acceptance remain unverified."
    },
    {
      "requirementID": "SUP-20261102-04-001",
      "requirement": "Fruit Basket questions.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:157",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-002",
      "requirement": "Question difficulty settings.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:158",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-003",
      "requirement": "Existing gameplay mechanics.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:159",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-004",
      "requirement": "Basket Reveal facts.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:160",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-005",
      "requirement": "Saved citations.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:161",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-006",
      "requirement": "Existing encyclopedia entries.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:162",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-007",
      "requirement": "Previously completed rounds.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:163",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-008",
      "requirement": "Ask retrieval.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:164",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-009",
      "requirement": "Cycle Tracker educational explanations.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:165",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-010",
      "requirement": "Existing user data.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:166",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-011",
      "requirement": "Research notes.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:174",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-012",
      "requirement": "Scientific claims.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:175",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-013",
      "requirement": "Supporting sources.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:176",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-014",
      "requirement": "Citation metadata.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:177",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-015",
      "requirement": "Topic classifications.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:178",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-016",
      "requirement": "Approved educational explanations.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:179",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-017",
      "requirement": "Content revisions.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:180",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-018",
      "requirement": "Fruit spawning.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:184",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-019",
      "requirement": "Fruit classification.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:185",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-020",
      "requirement": "Catch detection.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:186",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-021",
      "requirement": "Scoring.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:187",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-022",
      "requirement": "Difficulty mechanics.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:188",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-023",
      "requirement": "Obstacles.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:189",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-024",
      "requirement": "Star passes.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:190",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-025",
      "requirement": "Round completion.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:191",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-026",
      "requirement": "Game-state transitions.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:192",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-027",
      "requirement": "Stable research ID.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:200",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-028",
      "requirement": "Content version.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:201",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-029",
      "requirement": "Topic classification.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:202",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-030",
      "requirement": "Approved scientific content.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:203",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-031",
      "requirement": "Supporting source identifiers.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:204",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-032",
      "requirement": "Citation metadata.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:205",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-033",
      "requirement": "Source publication details.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:206",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-034",
      "requirement": "Revision metadata.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:207",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-035",
      "requirement": "Validation status.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:208",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-036",
      "requirement": "Retirement or supersession status where appropriate.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:209",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-EDUCATION-STRUCTURE-001",
      "requirement": "Pregnancy and contextual science educational payloads must remain associated with the requested topic and usable source identifiers; malformed or cross-topic payloads must fail closed.",
      "acceptanceStatus": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "relevantSourceFiles": [
        "Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyResearchBridge.swift",
        "Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyEducationViewModel.swift",
        "Fruitfolio/Cycle Tracker/Genetics + Body + Lab/Prompt27ResearchBridge.swift",
        "Fruitfolio/Cycle Tracker/Genetics + Body + Lab/Prompt27ScienceViewModel.swift"
      ],
      "supportingEvidence": [
        "FruitfolioTests/EducationalContentBoundaryTests.swift"
      ],
      "actualResult": "Five XCTest cases added, not executed. Closures and view models reject mismatched content, blank titles/bodies/source identifiers, duplicate source identifiers and invalid section associations. Structural preflight does not verify source approval or scientific accuracy. Default unavailable providers and unconnected action callbacks remain a separate PARTIAL production-integration gap; no clinical content was invented."
    },
    {
      "requirementID": "SUP-CYCLE-SETUP-WRITE-001",
      "requirement": "Cycle setup answers must not report failed writes as saved, expose uncommitted snapshots, or lose later edits through actor reentrancy.",
      "acceptanceStatus": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "relevantSourceFiles": [
        "Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingStore.swift",
        "Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingViewModel.swift",
        "Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingView.swift"
      ],
      "supportingEvidence": [
        "FruitfolioTests/CycleSetupPersistenceSafetyTests.swift"
      ],
      "actualResult": "Added serialized, cancellation-aware access and rollback of the in-memory draft on failed writes. Six tests exercise write failure, blocked persistence/concurrent edits/snapshots, cancellation, reload/save-queue ordering, and actual shared-context synchronization only after a successful save. Failed optimistic answers cannot alter shared health context; dismissing an error cannot allow completion of an older draft. Not executed in Xcode. Cross-file reconciliation with Prompt13 remains non-atomic if one persistence layer fails after the other has saved; this change does not claim a two-file transaction."
    },
    {
      "requirementID": "SUP-EXPORT-LIFECYCLE-001",
      "requirement": "Export preparation must not open a destination after navigation away, publish a cancelled/stale document, or mix later MainActor health/game edits into an already captured snapshot.",
      "acceptanceStatus": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "relevantSourceFiles": [
        "Fruitfolio/Privacy Settings/FruitfolioExportPreparation.swift",
        "Fruitfolio/Privacy Settings/Prompt12DataManagementView.swift",
        "Fruitfolio/Privacy Settings/FruitfolioPersonalDataExport.swift"
      ],
      "supportingEvidence": [
        "FruitfolioTests/ExportPreparationLifecycleTests.swift",
        "FruitfolioTests/ExportSnapshotConsistencyTests.swift"
      ],
      "actualResult": "Added cancellable request-owned preparation; Back/real disappearance cancels preparation, while native Files presentation remains intact. Late cancelled results cannot replace the active document. MainActor domain values are copied before awaiting cycle/setup snapshots. Four new tests cover cancellation, replacement, error and a deliberately blocked cycle-file read with later health/game edits. Not executed on Mac. Existing saved-file byte verification and Cancel/no-success behavior are unchanged.",
      "limitations": "This freezes MainActor data at request time; separately actor-owned cycle/setup snapshots are still individually read and are not a cross-file database transaction."
    },
    {
      "requirementID": "SUP-RESEARCH-QUOTATION-001",
      "requirement": "Supplemental scientific-integrity correction: presentation must preserve the actual quoted research, measurements, links and source identifiers.",
      "acceptanceStatus": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "relevantSourceFiles": [
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "supportingEvidence": [
        "FruitfolioTests/ResearchQuotationFidelityTests.swift",
        "FruitfolioTests/GroundingAttributionTests.swift"
      ],
      "actualResult": "Removed internal punctuation/whitespace rewriting from quoted research presentation. The prior prose-spacing heuristic could change domain names, DOI punctuation, citation markers and compound units after grounding validation. Only enclosing layout whitespace is trimmed; approved source text and package files are unchanged. Joined prose requires a separately reviewed source correction, not a display-time scientific rewrite. Three byte-fidelity unit tests plus an engine-to-save integration case covering selected-evidence and model-failure fixture paths were added. Not executed on Mac. Fixtures verify mechanics only, not clinical evidence or native inference."
    },
    {
      "requirementID": "SUP-GAME-QUESTION-LIFECYCLE-001",
      "requirement": "Late or cancelled question research must not replace a newer game topic/session, reopen a left screen or corrupt question-source/history association.",
      "acceptanceStatus": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "relevantSourceFiles": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift"
      ],
      "supportingEvidence": [
        "FruitfolioTests/FruitBasketQuestionLifecycleTests.swift"
      ],
      "actualResult": "Added owned request cancellation plus generation/session/topic/difficulty checks, including before error publication. Four tests added (including difficulty changes) with actual grounded question fixtures and deliberately noncooperative late callbacks; not executed."
    },
    {
      "requirementID": "SUP-GAME-QUESTION-INTEGRITY-001",
      "requirement": "Playable questions must have unambiguous choices and pinned, approved original evidence; requested topic/difficulty association must be correct.",
      "acceptanceStatus": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "relevantSourceFiles": [
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift",
        "Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift"
      ],
      "supportingEvidence": [
        "FruitfolioTests/FruitBasketQuestionIntegrityTests.swift",
        "FruitfolioTests/FruitBasketQuestionLifecycleTests.swift"
      ],
      "actualResult": "Malformed duplicate/blank option and citation identities, duplicate choice text, empty questions/explanations/version locks are rejected. A shared snapshot check requires the original passage/package, unique source records, approved-source display eligibility and nonempty original source versions. The adapter and actual question-loading boundary both require this snapshot; source IDs alone do not approve a scientific question. Three integrity XCTest cases with multiple malformed decoded-JSON subcases added; lifecycle coverage extended to difficulty changes (four lifecycle cases). Not executed on Mac."
    }
  ],
  "additional20261102": {
    "source": "Specification/Founder_Additional_Requirements_2026-11-02.txt",
    "uniqueChecklistItemsAdded": 72,
    "countsByWorkstream": {
      "1": 10,
      "2": 18,
      "3": 8,
      "4": 36
    },
    "pendingNarrativeRequirementsAlsoBinding": true
  }
}
