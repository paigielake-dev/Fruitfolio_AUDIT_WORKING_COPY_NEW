import SwiftUI
import ImageIO

/// Local file reading and bounded decoding happen outside SwiftUI body evaluation.
struct Prompt10ImportedImage: View {
    let imageID: String
    @State private var loaded: DecodedImage?
    @State private var unavailable = false

    // The immutable decoded CGImage is published once and never mutated.
    private struct DecodedImage: @unchecked Sendable {
        let image: CGImage
    }

    var body: some View {
        Group {
            if let loaded {
                Image(decorative: loaded.image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(false)
                    .accessibilityLabel("user imported image")
            } else if unavailable {
                Text("this local image is unavailable")
            } else {
                ProgressView().accessibilityLabel("loading local image")
            }
        }
        .task(id: imageID) {
            loaded = nil
            unavailable = false
            let requestedID = imageID
            let worker = Task.detached(priority: .utility) { () -> DecodedImage? in
                guard !Task.isCancelled,
                      let data = Prompt10LocalMediaStore.shared.data(for: requestedID),
                      data.count <= Prompt10ImagePreparation.maximumInputBytes,
                      let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1600
                ]
                guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
                      !Task.isCancelled else { return nil }
                return DecodedImage(image: image)
            }
            let result = await withTaskCancellationHandler(operation: { await worker.value }, onCancel: { worker.cancel() })
            guard !Task.isCancelled, requestedID == imageID else { return }
            loaded = result
            unavailable = result == nil
        }
    }
}
