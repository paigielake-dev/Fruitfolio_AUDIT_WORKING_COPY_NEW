import Foundation

/// Local numeric presentation only: never translate a preference value or write
/// a rounded percentage back to its original 0...1 storage representation.
enum FruitfolioSettingsPercentage {
    static func string(_ value: Double, locale: Locale) -> String? {
        guard value.isFinite, (0...1).contains(value) else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: value))
    }
}
