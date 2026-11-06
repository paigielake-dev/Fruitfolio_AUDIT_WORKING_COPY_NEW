#if DEBUG
import SwiftUI

private final class FruitfolioMeasurementFaultDefaults: UserDefaults, @unchecked Sendable {
    var dropNextWrite = false
    var dropNextErase = false
    var foreignOnDroppedWrite: Data?
    var writes = 0
    var erasures = 0
    override func set(_ value: Any?, forKey key: String) {
        guard key == "fixture" else { super.set(value, forKey: key); return }
        writes += 1
        if dropNextWrite {
            dropNextWrite = false
            if let foreignOnDroppedWrite { super.set(foreignOnDroppedWrite, forKey: key) }
            return
        }
        super.set(value, forKey: key)
    }
    override func removeObject(forKey key: String) {
        guard key == "fixture" else { super.removeObject(forKey: key); return }
        erasures += 1
        if dropNextErase { dropNextErase = false; return }
        super.removeObject(forKey: key)
    }
}

@MainActor
private final class FruitfolioMeasurementRegressionFixture: ObservableObject {
    static let recordID = UUID(uuidString: "CF310000-0000-0000-0000-000000000001")!
    let store: FruitfolioHormoneMeasurementStore
    let setupFailure: String?
    private let suite = "Fruitfolio.measurementUIQA." + UUID().uuidString
    let defaults: UserDefaults
    let baselineBytes: Data?
    init() {
        defaults = FruitfolioMeasurementFaultDefaults(suiteName: suite)!
        store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
        var failure: String?
        do {
            var record = FruitfolioHormoneMeasurement()
            record.id = Self.recordID
            record.result = "12.50"; record.unit = "pg/mL"
            record.resultLocaleIdentifier = "en_US"
            record.notes = "QA original note"
            record.reportedTestDay = try .init(year: 2026, month: 10, day: 16)
            try store.save(record)
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioMeasurementsUnknownFormat") {
                guard var legacy = store.records.first else { throw FruitfolioHormoneMeasurementError.unreadableStorage }
                legacy.result = "12,500"
                legacy.resultLocaleIdentifier = "unknown-report-format"
                defaults.set(try JSONEncoder().encode([legacy]), forKey: "fixture")
                store.reloadSavedMeasurements()
            }
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioMeasurementsFutureRecord") {
                let bytes = defaults.data(forKey: "fixture")!
                var object = try JSONSerialization.jsonObject(with: bytes) as! [[String: Any]]
                object[0]["futureQAField"] = true
                defaults.set(try JSONSerialization.data(withJSONObject: object), forKey: "fixture")
                store.reloadSavedMeasurements()
            }
        } catch { failure = "measurement QA fixture could not be prepared" }
        setupFailure = failure
        let args = ProcessInfo.processInfo.arguments
        if let fault = defaults as? FruitfolioMeasurementFaultDefaults {
            fault.writes = 0; fault.erasures = 0
            fault.dropNextWrite = args.contains("-fruitfolioMeasurementsDropNextWrite") || args.contains("-fruitfolioMeasurementsForeignAfterDrop")
            if args.contains("-fruitfolioMeasurementsForeignAfterDrop") {
                guard var newer = store.records.first else { preconditionFailure("Private measurement fixture has no baseline") }
                newer.result = "13.500"; newer.notes = "QA newer independent record"
                do { fault.foreignOnDroppedWrite = try JSONEncoder().encode([newer]) }
                catch { preconditionFailure("Could not encode private newer measurement fixture") }
            }
            fault.dropNextErase = args.contains("-fruitfolioMeasurementsDropNextErase")
        }
        baselineBytes = defaults.data(forKey: "fixture")
    }
    deinit { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
}

struct FruitfolioMeasurementRegressionHarness: View {
    @StateObject private var fixture = FruitfolioMeasurementRegressionFixture()
    @State private var presented = true
    @EnvironmentObject private var settings: SettingsStore
    var body: some View {
        Group {
            if let failure = fixture.setupFailure { Text(failure) }
            else if presented { FruitfolioHormoneInformationView(onBack: { presented = false }, store: fixture.store) }
            else { Button("open measurements QA") { presented = true } }
        }
        .overlay(alignment: .bottomLeading) {
            FruitfolioMeasurementWriteReadback(store: fixture.store, defaults: fixture.defaults, baseline: fixture.baselineBytes)
                .font(.caption2).allowsHitTesting(false)
        }
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            settings.reduceAnimationOverride = args.contains("-fruitfolioMeasurementsReduceMotion")
            settings.language = args.firstIndex(of: "-fruitfolioMeasurementsLanguage")
                .flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
                .flatMap(FruitfolioLanguage.init(rawValue:)) ?? .english
            settings.translationPausedForMemoryPressure = true
        }

    }
}
@MainActor
private struct FruitfolioMeasurementWriteReadback: View {
    @ObservedObject var store: FruitfolioHormoneMeasurementStore
    let defaults: UserDefaults
    let baseline: Data?
    var body: some View {
        // Independently decode the real backing bytes, not the editor cache.
        let persisted = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "fixture")
        VStack(alignment: .leading) {
            Text("persisted measurement count: \(persisted.records.count)").accessibilityIdentifier("measurementQA.persistedCount")
            Text("persisted result: " + (persisted.records.first?.result ?? "none")).accessibilityIdentifier("measurementQA.persistedResult")
            Text("persisted notes: " + (persisted.records.first?.notes ?? "none")).accessibilityIdentifier("measurementQA.persistedNotes")
            Text("original bytes intact: \(defaults.data(forKey: "fixture") == baseline)").accessibilityIdentifier("measurementQA.originalBytesIntact")
            Text("write protected: \(store.storageProtectionReason != nil)").accessibilityIdentifier("measurementQA.writeProtected")
            Text("write attempts: \((defaults as? FruitfolioMeasurementFaultDefaults)?.writes ?? -1)").accessibilityIdentifier("measurementQA.writeAttempts")
            Text("erase attempts: \((defaults as? FruitfolioMeasurementFaultDefaults)?.erasures ?? -1)").accessibilityIdentifier("measurementQA.eraseAttempts")
        }
    }
}

#endif
