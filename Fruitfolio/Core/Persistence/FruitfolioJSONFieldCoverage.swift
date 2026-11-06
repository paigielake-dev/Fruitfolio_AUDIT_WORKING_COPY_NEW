import Foundation

/// Detect keyed information a typed Codable round-trip would discard. Values
/// are not compared or normalized: strings, units and scientific provenance
/// remain owned by their domain. A mismatch protects the original from writes.
nonisolated enum FruitfolioJSONFieldCoverage {
    static func preservesFields(original: Data, encoded: Data) -> Bool {
        guard let original = try? JSONSerialization.jsonObject(with: original, options: [.fragmentsAllowed]),
              let encoded = try? JSONSerialization.jsonObject(with: encoded, options: [.fragmentsAllowed]) else { return false }
        return preservesFields(original, encoded, depth: 0)
    }
    private static func preservesFields(_ original: Any, _ encoded: Any, depth: Int) -> Bool {
        guard depth < 64 else { return false }
        if let original = original as? [String: Any] {
            guard let encoded = encoded as? [String: Any], Set(original.keys).isSubset(of: Set(encoded.keys)) else { return false }
            return original.allSatisfy { key, value in
                guard let counterpart = encoded[key] else { return false }
                return preservesFields(value, counterpart, depth: depth + 1)
            }
        }
        if let original = original as? [Any] {
            guard let encoded = encoded as? [Any], original.count == encoded.count else { return false }
            return zip(original, encoded).allSatisfy { preservesFields($0, $1, depth: depth + 1) }
        }
        // Scalar representation may legitimately change during legacy decoding;
        // this guard concerns lost fields, not schema/clinical validation.
        return !(encoded is [String: Any]) && !(encoded is [Any])
    }
}
