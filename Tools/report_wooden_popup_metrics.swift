import Foundation

@main
struct WoodenPopupMetricsReport {
    static func main() throws {
        let pixels = FruitfolioPopupLayout.woodenSignPixelSize
        let writing = FruitfolioPopupLayout.woodenSignWritingRect
        let report: [String: Any] = [
            "pixels": [Double(pixels.width), Double(pixels.height)],
            "normalizedWritingRect": [Double(writing.minX), Double(writing.minY), Double(writing.width), Double(writing.height)]
        ]
        FileHandle.standardOutput.write(try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]))
    }
}
