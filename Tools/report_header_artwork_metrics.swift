import Foundation

/// Emits actual production metadata for independent PNG measurement checks.
/// This reads no user data and performs no rendering or artwork modification.
@main
struct HeaderArtworkMetricsReport {
    static func main() throws {
        var records: [[String: Any]] = []
        for palette in FruitfolioHeaderArtworkPalette.allCases {
            for item in palette.items {
                records.append([
                    "palette": String(describing: palette), "id": item.id.rawValue,
                    "pixels": [Double(item.pixels.width), Double(item.pixels.height)],
                    "visibleAlphaBounds": [Double(item.paintedBounds.minX), Double(item.paintedBounds.minY),
                                           Double(item.paintedBounds.width), Double(item.paintedBounds.height)]])
            }
        }
        var output = try JSONSerialization.data(withJSONObject: records, options: [.sortedKeys])
        output.append(0x0a)
        FileHandle.standardOutput.write(output)
    }
}
