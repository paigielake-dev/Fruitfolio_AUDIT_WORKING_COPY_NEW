import Foundation

/// Protected tokens are verified after inference. A changed/missing/reordered
/// placeholder rejects the output instead of guessing how to repair a citation.
struct FruitfolioScientificTranslationEnvelope: Sendable {
    let original: String
    let prepared: String
    private let replacements: [(String, String)]
    private let protectionRegexPattern: String
    private let explicitProtectionPattern: String?

    init(_ source: String, protectedLiterals: [String] = []) throws {
        original = source
        let literalPatterns = protectedLiterals.filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }.map { NSRegularExpression.escapedPattern(for: $0) }
        explicitProtectionPattern = literalPatterns.isEmpty ? nil : literalPatterns.map { "(?:\($0))" }.joined(separator: "|")
        let patterns = literalPatterns + [
            // A bare DOI starts with a number. Protect the whole identifier
            // before the general numerical matcher can split its prefix.
            FruitfolioScientificQuantityProtection.referencePattern,
            FruitfolioScientificQuantityProtection.protectionPattern,
            #"\\[\\*_`\[\]<>]"#,
            #"</?u>"#,
            #"\*\*|__|(?<!\*)\*(?!\*)"#
        ]
        let pattern = patterns.map { "(?:\($0))" }.joined(separator: "|")
        protectionRegexPattern = pattern
        let regex = try NSRegularExpression(pattern: pattern)
        let ns = source as NSString
        let matches = regex.matches(in: source, range: NSRange(location: 0, length: ns.length))
        let prefix = "FFPROTECT_" + UUID().uuidString.replacingOccurrences(of: "-", with: "") + "_"
        var replacements: [(String, String)] = []
        let output = NSMutableString(string: source)
        for (index, match) in matches.enumerated() {
            replacements.append(("\(prefix)\(index)_END", ns.substring(with: match.range)))
        }
        for (index, match) in matches.enumerated().reversed() {
            output.replaceCharacters(in: match.range, with: replacements[index].0)
        }
        self.replacements = replacements
        prepared = output as String
    }

    func restore(_ translated: String) throws -> String {
        var lastEnd = translated.startIndex
        for (marker, _) in replacements {
            guard translated.components(separatedBy: marker).count == 2,
                  let range = translated.range(of: marker), range.lowerBound >= lastEnd else {
                throw FruitfolioTranslationError.protectedContentChanged
            }
            lastEnd = range.upperBound
        }
        var output = translated
        for (marker, original) in replacements { output = output.replacingOccurrences(of: marker, with: original) }
        try validateSignatures(output)
        return output
    }

    /// Catalog text has no generated placeholders. Preserve the source-specific
    /// protected token sequence while permitting ordinary translated words that
    /// merely resemble units (for example Norwegian "min"). This checks literal
    /// integrity, not semantic/clinical approval of a translation.
    func validateCatalogCandidate(_ candidate: String) throws -> String {
        let expected = replacements.map { $0.1 }
        let sourceLiterals = Set(expected)
        let regex = try NSRegularExpression(pattern: protectionRegexPattern)
        let ns = candidate as NSString
        let retained = regex.matches(in: candidate, range: NSRange(location: 0, length: ns.length))
            .map { ns.substring(with: $0.range) }.filter { sourceLiterals.contains($0) }
        guard retained == expected else {
            throw FruitfolioTranslationError.protectedContentChanged
        }
        try validateSignatures(candidate)
        return candidate
    }

    private func validateSignatures(_ candidate: String) throws {
        guard try FruitfolioScientificQuantityProtection.quantitySignature(candidate) == FruitfolioScientificQuantityProtection.quantitySignature(original),
              try FruitfolioScientificQuantityProtection.referenceSignature(candidate) == FruitfolioScientificQuantityProtection.referenceSignature(original),
              try FruitfolioScientificQuantityProtection.identifierSignature(candidate) == FruitfolioScientificQuantityProtection.identifierSignature(original) else {
            throw FruitfolioTranslationError.protectedContentChanged
        }
        if let explicitProtectionPattern {
            let regex = try NSRegularExpression(pattern: explicitProtectionPattern)
            func signature(_ text: String) -> [String] {
                let ns = text as NSString
                return regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
                    .map { ns.substring(with: $0.range) }
            }
            guard signature(candidate) == signature(original) else {
                throw FruitfolioTranslationError.protectedContentChanged
            }
        }
    }

}

enum FruitfolioTranslationOrigin: Equatable, Sendable { case source, catalog, machine }
struct FruitfolioDisplayTranslation: Equatable, Sendable {
    let text: String
    let origin: FruitfolioTranslationOrigin
}

actor FruitfolioTranslationService {
    static let shared = FruitfolioTranslationService(runtime: FruitfolioMADLADRuntime.shared)
    private let runtime: any FruitfolioLocalTranslationRuntime
    init(runtime: any FruitfolioLocalTranslationRuntime) { self.runtime = runtime }

    // Only simultaneous work is shared. Completed text is owned by its caller,
    // never retained here after the final waiter (including failed requests).
    private struct RequestKey: Hashable, Sendable {
        let source: Data
        let protectedLiterals: [Data]
        let sourceLanguage: Data
        let targetTag: String
    }
    private struct Flight: Sendable {
        let id: UUID
        let task: Task<FruitfolioDisplayTranslation, Error>
        var waiters: Set<UUID>
    }
    private var flights: [RequestKey: Flight] = [:]
    // Handles only, no source-key/result cache. Overflow callers still own
    // independent work, but service release must be able to cancel it as well.
    private var unsharedTasks: [UUID: Task<FruitfolioDisplayTranslation, Error>] = [:]

    #if DEBUG
    func debugInFlightStatistics() -> (requests: Int, waiters: Int, unshared: Int) {
        (flights.count, flights.values.reduce(0) { $0 + $1.waiters.count }, unsharedTasks.count)
    }
    #endif

    func releaseResources() async {
        let tasks = flights.values.map(\.task) + Array(unsharedTasks.values)
        flights.removeAll()
        unsharedTasks.removeAll()
        for task in tasks { task.cancel() }
        await runtime.releaseResources()
    }

    private func finishWaiter(key: RequestKey, flightID: UUID, waiter: UUID, cancelIfLast: Bool) {
        guard var flight = flights[key], flight.id == flightID else { return }
        flight.waiters.remove(waiter)
        if flight.waiters.isEmpty {
            flights.removeValue(forKey: key)
            if cancelIfLast { flight.task.cancel() }
        } else { flights[key] = flight }
    }

    func translate(_ source: String, language: FruitfolioLanguage, protectedLiterals: [String] = [],
                   sourceLanguage: String = "en", preferCatalog: Bool = true, bundle: Bundle = .main) async throws -> String {
        try await translateForDisplay(source, language: language, protectedLiterals: protectedLiterals,
            sourceLanguage: sourceLanguage, preferCatalog: preferCatalog, bundle: bundle).text
    }

    func translateForDisplay(_ source: String, language: FruitfolioLanguage, protectedLiterals: [String] = [],
                             sourceLanguage: String = "en", preferCatalog: Bool = true,
                             inferenceAllowed: Bool = true, bundle: Bundle = .main) async throws -> FruitfolioDisplayTranslation {
        try Task.checkCancellation()
        guard language.rawValue != sourceLanguage,
              !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .init(text: source, origin: .source)
        }
        // Catalog keys describe English source text. Never reinterpret a saved
        // non-English original as an English UI key, or rewrite saved records.
        if preferCatalog, sourceLanguage == "en",
           let candidate = FruitfolioLocalization.catalogValue(source, language: language, bundle: bundle),
           let accepted = try? FruitfolioScientificTranslationEnvelope(source, protectedLiterals: protectedLiterals)
                .validateCatalogCandidate(candidate) {
            try Task.checkCancellation()
            return .init(text: accepted, origin: .catalog)
        }
        guard inferenceAllowed else { throw FruitfolioTranslationError.pausedForMemoryPressure }
        // Only the simplified Chinese selector maps to the generic zh tag.
        // Traditional Chinese is not silently advertised as equivalent.
        let tag = language == .chineseSimplified ? "zh" : language.rawValue
        // Bound sharing metadata. Larger/distinct overflow requests retain the
        // original uncached path; no text is truncated or rejected by this policy.
        guard let key = sharingKey(source: source, protectedLiterals: protectedLiterals,
                                   sourceLanguage: sourceLanguage, targetTag: tag) else {
            return try await unsharedTranslate(source, protectedLiterals: protectedLiterals, targetTag: tag)
        }
        let waiter = UUID()
        let flight: Flight
        if var existing = flights[key], existing.waiters.count < 64 {
            existing.waiters.insert(waiter)
            flights[key] = existing
            flight = existing
        } else if flights[key] == nil, flights.count < 32 {
            let task = Task {
                try await self.machineTranslate(source, protectedLiterals: protectedLiterals, targetTag: tag)
            }
            flight = Flight(id: UUID(), task: task, waiters: [waiter])
            flights[key] = flight
        } else {
            return try await unsharedTranslate(source, protectedLiterals: protectedLiterals, targetTag: tag)
        }
        defer { finishWaiter(key: key, flightID: flight.id, waiter: waiter, cancelIfLast: false) }
        return try await withTaskCancellationHandler {
            let result = try await flight.task.value
            try Task.checkCancellation()
            return result
        } onCancel: {
            Task { await self.finishWaiter(key: key, flightID: flight.id, waiter: waiter, cancelIfLast: true) }
        }
    }

    private func unsharedTranslate(_ source: String, protectedLiterals: [String],
                                   targetTag: String) async throws -> FruitfolioDisplayTranslation {
        let id = UUID()
        let task = Task {
            try await self.machineTranslate(source, protectedLiterals: protectedLiterals, targetTag: targetTag)
        }
        unsharedTasks[id] = task
        defer { unsharedTasks.removeValue(forKey: id) }
        return try await withTaskCancellationHandler {
            let result = try await task.value
            try Task.checkCancellation()
            return result
        } onCancel: { task.cancel() }
    }

    private func sharingKey(source: String, protectedLiterals: [String],
                            sourceLanguage: String, targetTag: String) -> RequestKey? {
        guard source.utf8.count <= 16 * 1024, sourceLanguage.utf8.count <= 64,
              protectedLiterals.count <= 64 else { return nil }
        var literalBytes = 0
        for literal in protectedLiterals {
            let count = literal.utf8.count
            guard count <= 4096 - literalBytes else { return nil }
            literalBytes += count
        }
        // String equality normalizes Unicode; sharing must preserve original
        // bytes and the exact protection context instead of conflating records.
        return RequestKey(source: Data(source.utf8),
            protectedLiterals: protectedLiterals.map { Data($0.utf8) },
            sourceLanguage: Data(sourceLanguage.utf8), targetTag: targetTag)
    }

    private func machineTranslate(_ source: String, protectedLiterals: [String],
                                  targetTag: String) async throws -> FruitfolioDisplayTranslation {
        var translated: [String] = []
        for paragraph in source.components(separatedBy: "\n\n") {
            try Task.checkCancellation()
            if paragraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                translated.append(paragraph)
                continue
            }
            let envelope = try FruitfolioScientificTranslationEnvelope(paragraph, protectedLiterals: protectedLiterals)
            let result = try await runtime.translate(envelope.prepared, targetTag: targetTag)
            try Task.checkCancellation()
            translated.append(try envelope.restore(result))
        }
        return .init(text: translated.joined(separator: "\n\n"), origin: .machine)
    }
}
