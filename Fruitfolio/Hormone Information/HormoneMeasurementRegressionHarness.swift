#if DEBUG
import SwiftUI

@MainActor
private final class FruitfolioMeasurementRegressionFixture: ObservableObject {
    static let recordID = UUID(uuidString: "CF310000-0000-0000-0000-000000000001")!
    let store: FruitfolioHormoneMeasurementStore
    let setupFailure: String?
    private let suite = "Fruitfolio.measurementUIQA." + UUID().uuidString
    private let defaults: UserDefaults
    init() {
        defaults = UserDefaults(suiteName: suite)!
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
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioMeasurementsFutureRecord") {
                let bytes = defaults.data(forKey: "fixture")!
                var object = try JSONSerialization.jsonObject(with: bytes) as! [[String: Any]]
                object[0]["futureQAField"] = true
                defaults.set(try JSONSerialization.data(withJSONObject: object), forKey: "fixture")
                store.reloadSavedMeasurements()
            }
        } catch { failure = "measurement QA fixture could not be prepared" }
        setupFailure = failure
    }
    func cleanUp() { defaults.removePersistentDomain(forName: suite) }
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
        .onAppear {
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioMeasurementsReduceMotion")
        }
        .onDisappear { fixture.cleanUp() }
    }
}
#endif
