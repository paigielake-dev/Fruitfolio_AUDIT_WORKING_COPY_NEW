import Foundation

/// Protects literal scientific notation, never converts a value/unit or infers
/// what a measurement means. Source spelling, sign, case and spacing survive.
enum FruitfolioScientificQuantityProtection {
    private static let unitBase = #"(?:mIU|[µμu]IU|IU|mU|U|mEq|Eq|mmol|[µμu]mol|nmol|pmol|fmol|mol|kg|mg|mcg|[µμu]g|ng|pg|fg|g|mL|ml|dL|[µμu]L|L|mM|[µμu]M|nM|pM|fM|M|cm|mm|m|bpm|mmHg|min|ms|s|h|°C|°F|K|%|‰)"#
    private static let exponent = #"(?:\^\h*[+\-−]?\h*\p{N}+|[⁺⁻]?[⁰¹²³⁴⁵⁶⁷⁸⁹]+)?"#
    private static var unit: String {
        unitBase + exponent + #"(?:(?:/|·)\h*"# + unitBase + exponent + #")*(?![\p{L}])"#
    }
    private static let comparison = #"(?:\\?[<>]=?|≤|≥|≈|=|~)"#
    private static let labLabel = #"(?:FSH|LH|TSH|AMH|hCG|HCG|DHEA-S|HbA1c|pH|p|P|[A-Z][A-Z0-9_-]*[0-9][A-Z0-9_-]*)"#
    private static let number = #"(?:[+\-−±]\h*)?(?:\p{N}+(?:[.,٫٬]\p{N}+|\h+\p{N}{3}(?!\p{N}))*|[.,٫]\p{N}+)(?:[eE][+\-−]?\p{N}+|\h*(?:[×x]|\\?\*)\h*10\h*(?:\^\h*[+\-−]?\h*\p{N}+|[⁺⁻]?[⁰¹²³⁴⁵⁶⁷⁸⁹]+))?(?:\^\h*[+\-−]?\h*\p{N}+)?"#

    static var quantityPattern: String {
        let endpoint = number + #"(?:\h*(?i:"# + unit + #"))?"#
        return #"(?:\b"# + labLabel + #"\h*"# + comparison + #"\h*)?(?:"# +
            comparison + #"\h*)?"# + endpoint +
            #"(?:\h*(?:\+/-|±|[-−–—:/])\h*"# + endpoint + #")*"#
    }

    static var protectionPattern: String {
        // Apostrophe boundaries avoid interpreting translated contractions as
        // isolated unit symbols. The quantity signature below excludes bare
        // words such as Norwegian "min", which can also be a unit abbreviation.
        let bareUnit = #"(?<![\p{L}\p{N}_'’])"# + unit + #"(?![\p{L}\p{N}_'’])"#
        return "(?:" + quantityPattern + ")|(?:" + bareUnit + ")|(?:" + identifierPattern + ")"
    }

    // These are explicit scientific identifiers, unlike ambiguous ordinary
    // words such as "min" which may also be a unit abbreviation.
    static let identifierPattern = #"\b(?:HLA-[A-Z0-9]+\*[0-9:]+|HbA1c|hCG|pH|FSH|LH|TSH|AMH|DHEA-S|rs[0-9]+|[A-Z][A-Z0-9_-]*[0-9][A-Z0-9_-]*)\b"#

    static func identifierSignature(_ text: String) throws -> [String] {
        try matches(identifierPattern, in: text)
    }

    static let referencePattern = #"https?://[^\s<>]+|[\[［][^\]］\n]{1,200}[\]］]|[\(（][^\)）\n]*\b(?:(?:1[6-9]|20|21)\d{2}[a-z]?|(?i:n\.\h*d\.))[^\)）\n]*[\)）]"#

    static func quantitySignature(_ text: String) throws -> [String] {
        try matches(quantityPattern, in: text)
    }

    static func referenceSignature(_ text: String) throws -> [String] {
        try matches(referencePattern, in: text)
    }

    private static func matches(_ pattern: String, in text: String) throws -> [String] {
        let regex = try NSRegularExpression(pattern: pattern)
        let source = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: source.length)).map { source.substring(with: $0.range) }
    }
}
