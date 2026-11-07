import Foundation

struct FruitfolioLifeBridgeSnapshot: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let sourceURL: URL
    let retrievedAt: Date
    let reviewedAt: Date
    let version: String
    let approvedText: String
}

struct FruitfolioLifeBridgeContent: Codable, Equatable, Sendable {
    let snapshots: [FruitfolioLifeBridgeSnapshot]
    let officialApplicationURL: URL?
    let relationshipDisclosure: String?
    let sourceDiscrepancies: [String]?

    init(snapshots: [FruitfolioLifeBridgeSnapshot], officialApplicationURL: URL?, relationshipDisclosure: String?,
         sourceDiscrepancies: [String]? = nil) {
        self.snapshots = snapshots
        self.officialApplicationURL = officialApplicationURL
        self.relationshipDisclosure = relationshipDisclosure
        self.sourceDiscrepancies = sourceDiscrepancies
    }

    /// Preserve curator order within each publisher, with official operational
    /// information first. Never silently merge the two publishers' assertions.
    var orderedSnapshots: [FruitfolioLifeBridgeSnapshot] {
        snapshots.enumerated().sorted { lhs, rhs in
            let leftOfficial = lhs.element.sourceURL.host?.lowercased() == "lifebridgesurrogacy.com"
            let rightOfficial = rhs.element.sourceURL.host?.lowercased() == "lifebridgesurrogacy.com"
            return leftOfficial == rightOfficial ? lhs.offset < rhs.offset : leftOfficial
        }.map(\.element)
    }

    func informationalAnswer(originalQuestion: String, query: String) -> AskAnswer? {
        guard validate() else { return nil }
        let terms = FruitfolioQueryNormalizer.tokens(query)
        var selected: [FruitfolioLifeBridgeSnapshot] = []
        for host in ["lifebridgesurrogacy.com", "fruitsoflifexo.carrd.co"] {
            var best: FruitfolioLifeBridgeSnapshot?
            var bestScore = -1
            for snapshot in snapshots where snapshot.sourceURL.host?.lowercased() == host {
                let titleTokens = FruitfolioQueryNormalizer.tokens(snapshot.title)
                let bodyTokens = FruitfolioQueryNormalizer.tokens(snapshot.approvedText)
                let score = 3 * terms.intersection(titleTokens).count + terms.intersection(bodyTokens).count
                if score > bestScore { best = snapshot; bestScore = score }
            }
            if let best { selected.append(best) }
        }
        guard selected.count == 2 else { return nil }
        var sections = ["let’s keep the sources separate. ☆ these are reviewed publisher excerpts, not independent medical evidence or an assessment of your eligibility. LifeBridge’s official source takes priority for organization-specific details."]
        for snapshot in selected {
            let role = snapshot.sourceURL.host?.lowercased() == "lifebridgesurrogacy.com"
                ? "LifeBridge official information" : "FruitsofLife.xo founder context"
            // Complete approved text: no generated facts or sliced qualifiers.
            let quoted = FruitfolioSemanticMarkup.markdown([.init(text: snapshot.approvedText)])
            sections.append("☆ **" + role + "**\n" + quoted)
        }
        if let disclosure = relationshipDisclosure, !disclosure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("- Fruitfolio relationship disclosure:\n" + FruitfolioSemanticMarkup.markdown([.init(text: disclosure)]))
        }
        if let differences = sourceDiscrepancies, !differences.isEmpty {
            sections.append("- source differences flagged for founder review:\n" +
                differences.map { FruitfolioSemanticMarkup.markdown([.init(text: $0)]) }.joined(separator: "\n"))
        }
        sections.append("check the official website for current eligibility, application, and contact details. these excerpts do not establish that you qualify or replace medical guidance.")
        let records = selected.map { snapshot in
            AskSourceRecord(id: "lifebridge-publisher:" + snapshot.id, title: snapshot.title,
                sourceText: "first-party publisher information\nretrieved " + snapshot.retrievedAt.ISO8601Format()
                    + "\nreviewed " + snapshot.reviewedAt.ISO8601Format() + "\nversion " + snapshot.version,
                urlString: snapshot.sourceURL.absoluteString, doi: nil, publicationData: nil, contentVersion: snapshot.version)
        }
        return AskAnswer(originalQuestion: originalQuestion, answerText: sections.joined(separator: "\n\n"),
            support: .partiallySupported, sourceIDs: records.map(\.id), sources: records,
            knowledgeBaseVersion: "lifebridge-publishers:" + selected.map { $0.id + "@" + $0.version }.joined(separator: ";"),
            answerPath: .publisherInformation)
    }

    private static func isOfficialURL(_ url: URL, hosts: Set<String>) -> Bool {
        url.scheme?.lowercased() == "https" && hosts.contains(url.host?.lowercased() ?? "") &&
            url.user == nil && url.password == nil && (url.port == nil || url.port == 443)
    }
    private static func hasVisibleContent(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func validate(now: Date = Date()) -> Bool {
        guard now.timeIntervalSinceReferenceDate.isFinite else { return false }
        let hosts = Set(snapshots.compactMap { $0.sourceURL.host?.lowercased() })
        guard hosts.contains("lifebridgesurrogacy.com"), hosts.contains("fruitsoflifexo.carrd.co"),
              Set(snapshots.map(\.id)).count == snapshots.count else { return false }
        guard snapshots.allSatisfy({ snapshot in
            Self.isOfficialURL(snapshot.sourceURL, hosts: ["lifebridgesurrogacy.com", "fruitsoflifexo.carrd.co"]) &&
            [snapshot.id, snapshot.title, snapshot.version, snapshot.approvedText].allSatisfy(Self.hasVisibleContent) &&
            snapshot.retrievedAt.timeIntervalSinceReferenceDate.isFinite && snapshot.reviewedAt.timeIntervalSinceReferenceDate.isFinite &&
            snapshot.retrievedAt <= snapshot.reviewedAt && snapshot.reviewedAt <= now
        }) else { return false }
        if let sourceDiscrepancies, !sourceDiscrepancies.allSatisfy(Self.hasVisibleContent) { return false }
        if let application = officialApplicationURL {
            guard Self.isOfficialURL(application, hosts: ["lifebridgesurrogacy.com"]) else { return false }
        }
        return true
    }
}

enum FruitfolioLifeBridgeInformation {
    static let awaitingStatus = "awaiting_verified_lifebridge_content"
    static let missingContent = "details not available in the approved library yet"
    static let officialURL = URL(string: "https://lifebridgesurrogacy.com/")
    static let founderURL = URL(string: "https://fruitsoflifexo.carrd.co/")
    static let founderInstagramURL = URL(string: "https://www.instagram.com/fruitsoflife.xo/")

    static func isOrganizationQuestion(_ question: String) -> Bool {
        let text = question.lowercased()
        return text.contains("lifebridge") || text.contains("life bridge")
    }
    /// Scope publisher material to organization information, not unrelated
    /// medical questions which merely mention the organization or surrogacy.
    static func isInformationQuestion(_ question: String) -> Bool {
        let words = Set(question.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
        guard words.contains("lifebridge") || (words.contains("life") && words.contains("bridge")) else { return false }
        let topics: Set<String> = ["eligibility", "eligible", "qualify", "qualification", "requirements", "apply", "application",
            "contact", "website", "process", "services", "program", "referral", "relationship", "founder", "fees", "compensation"]
        if !words.isDisjoint(with: topics) { return true }
        let overview: Set<String> = ["what", "is", "who", "are", "tell", "me", "about", "information", "info", "please",
            "the", "a", "an", "of", "on", "lifebridge", "life", "bridge", "surrogacy", "company", "organization", "agency"]
        return words.isSubset(of: overview)
    }

    static func protectedNames(in question: String) -> [String] {
        guard question.utf8.count <= FruitfolioTranslationService.maximumInputBytes else { return [] }
        // Latin boundaries reject LifeBridgeBank while allowing adjacent CJK
        // particles/Arabic text around the exact supplied proper identifier.
        let pattern = #"(?<![A-Za-z0-9])(?:lifebridge(?:[\p{Zs}\s]+surrogacy)?|life[\p{Zs}\s]+bridge|fruitsoflife\.xo|fruitfolio)(?![A-Za-z0-9])"#
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let source = question as NSString
        var cursor = 0
        var seen: Set<Data> = []
        var result: [String] = []
        var bytes = 0
        while cursor < source.length,
              let match = expression.firstMatch(in: question, range: NSRange(location: cursor, length: source.length - cursor)) {
            let literal = source.substring(with: match.range)
            let data = Data(literal.utf8)
            if seen.insert(data).inserted {
                result.append(literal)
                bytes += data.count
            }
            cursor = NSMaxRange(match.range)
            // Include the overflow entry: the service then rejects the whole
            // request instead of silently omitting remaining identifiers.
            if result.count > FruitfolioTranslationService.maximumProtectedLiterals ||
                bytes > FruitfolioTranslationService.maximumProtectedLiteralBytes { break }
        }
        return result
    }

    static func isDiscoverable(for question: String) -> Bool {
        isOrganizationQuestion(question) || question.localizedCaseInsensitiveContains("surrogacy")
    }
    static func load(bundle: Bundle = .main) -> FruitfolioLifeBridgeContent? {
        guard let url = bundle.url(forResource: "LifeBridgeApprovedContent", withExtension: "json") else { return nil }
        return load(at: url)
    }

    static func load(at url: URL) -> FruitfolioLifeBridgeContent? {
        // Loading approved content is strictly local. Publisher links are opened
        // separately by explicit user action, never fetched during inference.
        guard url.isFileURL, ["", "localhost"].contains(url.host?.lowercased() ?? ""),
              let file = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? file.close() }
        let limit = 8 * 1024 * 1024
        guard let data = try? file.read(upToCount: limit + 1), data.count <= limit else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let content = try? decoder.decode(FruitfolioLifeBridgeContent.self, from: data), content.validate() else { return nil }
        return content
    }
}
