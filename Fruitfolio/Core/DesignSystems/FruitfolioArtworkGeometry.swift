import Foundation
import CoreGraphics

/// Measured from the original PNGs. Screen owners still choose the artwork and anchor.
nonisolated struct FruitfolioArtworkGeometry: Decodable, Sendable {
    let width: Double
    let height: Double
    let visibleBounds: [Double]?

    func paintedBounds(in renderedSize: CGSize) -> CGRect? {
        guard width.isFinite, height.isFinite, renderedSize.width.isFinite, renderedSize.height.isFinite,
              width > 0, height > 0, renderedSize.width > 0, renderedSize.height > 0,
              let bounds = visibleBounds, bounds.count == 4,
              bounds.allSatisfy({ $0.isFinite }), bounds[0] >= 0, bounds[1] >= 0,
              bounds[2] <= width, bounds[3] <= height,
              bounds[2] > bounds[0], bounds[3] > bounds[1] else { return nil }
        return CGRect(x: bounds[0] / width * renderedSize.width,
                      y: bounds[1] / height * renderedSize.height,
                      width: (bounds[2] - bounds[0]) / width * renderedSize.width,
                      height: (bounds[3] - bounds[1]) / height * renderedSize.height)
    }
}

nonisolated enum FruitfolioArtworkGeometryStore {
    private nonisolated struct Catalog: Decodable { let assets: [String: FruitfolioArtworkGeometry] }
    private static let catalog: [String: FruitfolioArtworkGeometry] = {
        guard let url = Bundle.main.url(forResource: "ArtworkGeometry", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(Catalog.self, from: data) else { return [:] }
        return value.assets
    }()

    static func geometry(named name: String) -> FruitfolioArtworkGeometry? { catalog[name] }
}
