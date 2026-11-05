import Foundation
import ImageIO
import UniformTypeIdentifiers

enum Prompt10ImagePreparationError: Error {
    case invalidImage, imageTooLarge, encodingFailed
}

/// Only user-imported images pass through this pipeline. Founder artwork and
/// research assets are never rewritten. Re-encoding excludes camera metadata.
enum Prompt10ImagePreparation {
    static let maximumInputBytes = 30 * 1024 * 1024
    static let maximumDimension = 2048

    static func prepare(_ data: Data) async throws -> Data {
        let task = Task.detached(priority: .userInitiated) { () throws -> Data in
            try Task.checkCancellation()
            guard data.count <= maximumInputBytes else { throw Prompt10ImagePreparationError.imageTooLarge }
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  CGImageSourceGetCount(source) > 0,
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
                  let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
                  width.doubleValue > 0, height.doubleValue > 0,
                  width.doubleValue * height.doubleValue <= 150_000_000 else {
                throw Prompt10ImagePreparationError.invalidImage
            }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maximumDimension,
                kCGImageSourceShouldCacheImmediately: true
            ]
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                throw Prompt10ImagePreparationError.invalidImage
            }
            try Task.checkCancellation()
            let output = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(output as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
                throw Prompt10ImagePreparationError.encodingFailed
            }
            CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { throw Prompt10ImagePreparationError.encodingFailed }
            try Task.checkCancellation()
            return output as Data
        }
        return try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
    }
}
