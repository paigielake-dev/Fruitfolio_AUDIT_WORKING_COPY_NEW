import Foundation

enum RecordedHormone: String, CaseIterable, Codable, Identifiable, Sendable {
    case estradiol, progesterone, lh, fsh, testosterone, prolactin, amh, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .estradiol: return "estradiol (E2)"
        case .progesterone: return "progesterone"
        case .lh: return "luteinizing hormone (LH)"
        case .fsh: return "follicle-stimulating hormone (FSH)"
        case .testosterone: return "testosterone"
        case .prolactin: return "prolactin"
        case .amh: return "anti-Müllerian hormone (AMH)"
        case .other: return "other hormone"
        }
    }
}

struct HormoneMeasurement: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var hormone: RecordedHormone = .estradiol
    var otherHormoneName = ""
    var result = ""
    var unit = ""
    var testDate = Date()
    var sampleType = ""
    var cycleDay = ""
    var laboratoryReferenceRange = ""
    var notes = ""
    var createdAt = Date()
    var updatedAt = Date()

    var displayName: String { hormone == .other ? otherHormoneName : hormone.title }

    /// Preserve the original number and unit strings; never convert or interpret them.
    var validationError: String? {
        let number = result.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[+-]?[0-9]+(?:[.,][0-9]+)?$"#
        guard number.range(of: pattern, options: .regularExpression) != nil,
              Decimal(string: number.replacingOccurrences(of: ",", with: "."),
                      locale: Locale(identifier: "en_US_POSIX")) != nil else {
            return "enter a numerical result using digits and an optional decimal separator."
        }
        guard !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "enter the unit exactly as shown on your result."
        }
        if hormone == .other {
            let name = otherHormoneName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count <= 100 else { return "enter a hormone name of 1–100 characters." }
        }
        if !cycleDay.isEmpty {
            guard cycleDay.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let day = Int(cycleDay), day > 0 else { return "cycle day must be a positive whole number, or left blank." }
        }
        return nil
    }
}
