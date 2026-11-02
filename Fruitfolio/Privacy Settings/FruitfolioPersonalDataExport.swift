import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A readable user-requested record, not an encrypted backup or remote sync.
/// Binary image originals are explicitly excluded; their saved metadata remains.
struct FruitfolioPersonalDataExport: Codable {
    let schemaVersion: Int
    let dateRepresentation: String?
    let createdAt: Date
    let account: Prompt12AccountIdentity?
    let publicUsername: String
    let settings: Preferences
    let encyclopediasAndGuides: [Prompt10Encyclopedia]
    let cycleArchive: Prompt13CycleArchive
    let cycleSetup: Prompt14OnboardingDraft
    let reportedContext: Prompt27AUserReproductiveContext
    let hormoneMeasurements: [HormoneMeasurement]
    let fruitBasketProgress: [String: Prompt28TopicProgress]
    let fruitBasketQuestionHistory: [String: [String]]
    let limitations: [String]

    struct Preferences: Codable {
        let allAudioMuted: Bool
        let musicEnabled: Bool
        let rainEnabled: Bool
        let soundEffectsEnabled: Bool
        let typingASMREnabled: Bool
        let musicVolume: Double
        let rainVolume: Double
        let soundEffectsVolume: Double
        let typingVolume: Double
        let reduceAnimationOverride: Bool
        let language: String

        @MainActor init(_ settings: SettingsStore) {
            allAudioMuted = settings.allAudioMuted; musicEnabled = settings.musicEnabled
            rainEnabled = settings.rainEnabled; soundEffectsEnabled = settings.soundEffectsEnabled
            typingASMREnabled = settings.typingASMREnabled; musicVolume = settings.musicVolume
            rainVolume = settings.rainVolume; soundEffectsVolume = settings.soundEffectsVolume
            typingVolume = settings.typingVolume; reduceAnimationOverride = settings.reduceAnimationOverride
            language = settings.language.rawValue
        }
    }

    @MainActor
    static func capture(account: Prompt12AccountIdentity?, username: String, settings: SettingsStore,
                        library: Prompt10SavedLibraryStore, context: Prompt27AContextStore,
                        hormones: HormoneMeasurementStore,
                        cycle: Prompt13CycleStore = .shared, onboarding: Prompt14CycleOnboardingStore = .shared,
                        fruitBasket: Prompt28FruitBasketStore? = nil, now: Date = Date()) async throws -> Data {
        guard library.loadError == nil, hormones.loadError == nil, !context.didRecoverCorruptStoredContext else {
            throw Prompt12AccountPrivacyError.exportFailed
        }
        let fruitBasket = fruitBasket ?? Prompt28FruitBasketStore()
        guard fruitBasket.loadError == nil else { throw Prompt12AccountPrivacyError.exportFailed }
        // Read the actual domain stores. No raw defaults dump, credentials,
        // purchase receipts, model binaries or unrelated files are exported.
        async let archive = cycle.snapshot()
        async let setup = onboarding.snapshot()
        let export = try await FruitfolioPersonalDataExport(schemaVersion: 2,
            dateRepresentation: "seconds since 2001-01-01T00:00:00Z; exact stored Foundation Date value", createdAt: now,
            account: account, publicUsername: username, settings: Preferences(settings),
            encyclopediasAndGuides: library.encyclopedias,
            cycleArchive: archive, cycleSetup: setup, reportedContext: context.context,
            hormoneMeasurements: hormones.measurements, fruitBasketProgress: fruitBasket.topicProgress,
            fruitBasketQuestionHistory: fruitBasket.questionHistory.mapValues { $0.sorted() },
            limitations: ["Readable JSON includes sensitive health and personal data. Store and share it carefully.",
                          "User-imported image file contents are not included; saved page attachment metadata is retained. This is not a complete media backup.",
                          "Ask conversations are session-only and are not exported. Saved answers and their original source snapshots remain in encyclopedias and guides.",
                          "No remote account data, production purchase receipt, credentials, or research/model binaries are included."])
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // Epoch conversion adds978307200 and multiplies1000. At contemporary
        // timestamps this can lose the least significant bit of a stored Date.
        // Keep its original reference-seconds Double; schema/metadata make the
        // coordinate system explicit to readers. Clinical values are unchanged.
        encoder.dateEncodingStrategy = .deferredToDate
        return try encoder.encode(export)
    }

    static func decodeDocument(_ data: Data) throws -> FruitfolioPersonalDataExport {
        struct Version: Decodable { let schemaVersion: Int }
        let version = try JSONDecoder().decode(Version.self, from: data).schemaVersion
        let decoder = JSONDecoder()
        switch version {
        case 1: decoder.dateDecodingStrategy = .millisecondsSince1970
        case 2: decoder.dateDecodingStrategy = .deferredToDate
        default: throw CocoaError(.fileReadCorruptFile)
        }
        return try decoder.decode(FruitfolioPersonalDataExport.self, from: data)
    }
}

nonisolated struct FruitfolioPersonalDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    /// A successful system destination callback is followed by a real read of
    /// that file. Exact bytes and readable JSON are required; no store changes,
    /// path logging, deletion, or claim of a complete media backup occurs here.
    static func verifySavedFile(at url: URL, expected: Data) throws {
        guard url.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme) }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let saved = try Data(contentsOf: url)
        guard saved == expected else { throw CocoaError(.fileReadCorruptFile) }
        _ = try JSONSerialization.jsonObject(with: saved)
    }

    func makeFileWrapper() -> FileWrapper { FileWrapper(regularFileWithContents: data) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        makeFileWrapper()
    }
}
