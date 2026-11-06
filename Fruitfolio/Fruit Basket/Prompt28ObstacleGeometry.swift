import Foundation

nonisolated struct Prompt28ObstacleMaskLibrary: Sendable {
    struct Mask: Sendable {
        let name: String
        let sourceSize: CGSize
        let alphaBounds: CGRect
        let sourceSHA256: String
        let columns: Int
        let rows: Int
        private let bits: Data

        fileprivate init(_ record: Record) throws {
            guard (1...256).contains(record.columns), (1...256).contains(record.rows),
                  record.sourceWidth > 0, record.sourceHeight > 0,
                  record.alphaBounds.count == 4, record.alphaBounds.allSatisfy({ $0.isFinite }),
                  let data = Data(base64Encoded: record.bits), data.count == (record.columns * record.rows + 7) / 8
            else { throw Failure.invalidManifest }
            let bounds = CGRect(x: record.alphaBounds[0], y: record.alphaBounds[1], width: record.alphaBounds[2], height: record.alphaBounds[3])
            guard bounds.minX >= 0, bounds.minY >= 0, bounds.maxX <= 1, bounds.maxY <= 1, !bounds.isEmpty,
                  record.sha256.count == 64 else { throw Failure.invalidManifest }
            name = record.name; sourceSize = CGSize(width: record.sourceWidth, height: record.sourceHeight)
            alphaBounds = bounds; sourceSHA256 = record.sha256
            columns = record.columns; rows = record.rows; bits = data
        }
        func isPainted(column: Int, row: Int) -> Bool {
            guard column >= 0, row >= 0, column < columns, row < rows else { return false }
            let index = row * columns + column
            return bits[index / 8] & (1 << (index % 8)) != 0
        }
        func intersects(_ object: CGRect, imageFrame: CGRect, mirroredX: Bool = false) -> Bool {
            guard [object.minX, object.minY, object.width, object.height, imageFrame.minX, imageFrame.minY,
                   imageFrame.width, imageFrame.height].allSatisfy(\.isFinite),
                  imageFrame.width > 0, imageFrame.height > 0, object.width > 0, object.height > 0 else { return false }
            let area = object.intersection(imageFrame)
            guard !area.isNull, !area.isEmpty else { return false }
            let left = max(0, min(columns - 1, Int(floor((area.minX - imageFrame.minX) / imageFrame.width * CGFloat(columns)))))
            let right = max(0, min(columns - 1, Int(ceil((area.maxX - imageFrame.minX) / imageFrame.width * CGFloat(columns))) - 1))
            let top = max(0, min(rows - 1, Int(floor((area.minY - imageFrame.minY) / imageFrame.height * CGFloat(rows)))))
            let bottom = max(0, min(rows - 1, Int(ceil((area.maxY - imageFrame.minY) / imageFrame.height * CGFloat(rows))) - 1))
            guard left <= right, top <= bottom else { return false }
            for row in top...bottom {
                for column in left...right {
                    if isPainted(column: mirroredX ? columns - 1 - column : column, row: row) { return true }
                }
            }
            return false
        }
    }
    fileprivate struct Record: Decodable {
        let name: String
        let sourceWidth: Int
        let sourceHeight: Int
        let sha256: String
        let columns: Int
        let rows: Int
        let alphaBounds: [Double]
        let bits: String
    }
    private struct Manifest: Decodable { let version: Int; let alphaThreshold: Int; let masks: [Record] }
    enum Failure: Error { case missingManifest, invalidManifest }
    let masks: [String: Mask]
    static let bundled: Self? = try? load(url: Bundle.main.url(forResource: "Prompt28ObstacleMasks", withExtension: "json"))
    static func load(url: URL?) throws -> Self {
        guard let url else { throw Failure.missingManifest }
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: url))
        guard manifest.version == 1, manifest.alphaThreshold == 32,
              manifest.masks.count == 3, Set(manifest.masks.map(\.name)) == Set(["vines", "branch", "puddle"]) else { throw Failure.invalidManifest }
        let masks = try manifest.masks.map { ($0.name, try Mask($0)) }
        return Self(masks: Dictionary(uniqueKeysWithValues: masks))
    }
}

/// Shared renderer/physics frames follow the actual source aspect and painted
/// bounds. Mirroring the branch puts its thick root at the playfield's right edge.
nonisolated struct Prompt28ObstacleGeometry: Sendable {
    let playfield: CGSize
    let level: Int
    let library: Prompt28ObstacleMaskLibrary
    var isValid: Bool { playfield.width.isFinite && playfield.height.isFinite && playfield.width > 0 && playfield.height > 0 }
    func frame(_ name: String) -> CGRect? {
        guard isValid, let mask = library.masks[name] else { return nil }
        let width: CGFloat
        let centerY: CGFloat
        switch name {
        case "vines": width = playfield.width * (level == 2 ? 0.20 : 0.30); centerY = playfield.height * 0.54
        case "branch": width = min(playfield.width * 0.30, 176); centerY = playfield.height * 0.40
        case "puddle":
            width = min(playfield.width * 0.34, 190)
            let basket = Prompt28CatchGeometry(playfield: playfield)
            centerY = basket.artRect(basketX: 0.5).maxY - basket.basketArtSize.height * 0.42
        default: return nil
        }
        let height = width * mask.sourceSize.height / mask.sourceSize.width
        let left: CGFloat
        switch name {
        case "vines": left = -2 - width * mask.alphaBounds.minX
        case "branch": left = playfield.width + 2 - width * (1 - mask.alphaBounds.minX)
        default: left = (playfield.width - width) / 2
        }
        return CGRect(x: left, y: centerY - height / 2, width: width, height: height)
    }
    func touches(_ name: String, object: CGRect) -> Bool {
        guard let mask = library.masks[name], let frame = frame(name) else { return false }
        return mask.intersects(object, imageFrame: frame, mirroredX: name == "branch")
    }
    func objectRect(x: Double, y: Double, size: CGFloat) -> CGRect {
        CGRect(x: playfield.width * x - size / 2, y: playfield.height * y - size / 2, width: size, height: size)
    }
    func basketTouchesPuddle(at x: Double) -> Bool {
        let art = Prompt28CatchGeometry(playfield: playfield).artRect(basketX: x)
        let base = CGRect(x: art.minX + art.width * 0.15, y: art.minY + art.height * 0.76,
                          width: art.width * 0.70, height: art.height * 0.20)
        return touches("puddle", object: base)
    }
}
