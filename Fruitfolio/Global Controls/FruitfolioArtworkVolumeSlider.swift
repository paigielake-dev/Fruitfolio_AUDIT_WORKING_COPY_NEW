import SwiftUI
import UIKit

@MainActor
private enum FruitfolioSliderArtwork {
    static let track: UIImage? = {
        guard let image = try? FruitfolioAssetLoader.uiImage(.control_slider_lines), let cg = image.cgImage else { return nil }
        let size = CGSize(width: cg.width, height: cg.height)
        // Alpha bounds measured from the approved 1536 x 941 PNG's middle
        // painted track: x=124...1431, y=430...499. Scale only its native crop.
        let region = CGRect(x: size.width * (124.0 / 1536.0), y: size.height * (430.0 / 941.0),
                            width: size.width * (1307.0 / 1536.0), height: size.height * (69.0 / 941.0)).integral
        guard let crop = cg.cropping(to: region) else { return nil }
        return UIImage(cgImage: crop)
    }()
    static let knob: UIImage? = {
        guard let image = try? FruitfolioAssetLoader.uiImage(.control_slider_knob), let cg = image.cgImage else { return nil }
        let size = CGSize(width: cg.width, height: cg.height)
        let region = FruitfolioArtworkGeometryStore.geometry(named: "control_slider_knob")?.paintedBounds(in: size)
            ?? CGRect(origin: .zero, size: size)
        guard let crop = cg.cropping(to: region.integral) else { return nil }
        return UIImage(cgImage: crop)
    }()
}

/// A real adjustable UIKit control using the original painted track and knob.
/// Native touch, VoiceOver adjustment, and XCTest scrubber geometry agree.
struct FruitfolioArtworkVolumeSlider: UIViewRepresentable {
    let title: String
    @Binding var value: Double
    @Environment(\.layoutDirection) private var direction

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider(frame: .zero)
        slider.minimumValue = 0; slider.maximumValue = 1
        if let track = FruitfolioSliderArtwork.track {
            let painted = UIGraphicsImageRenderer(size: CGSize(width: 260, height: 14)).image { _ in
                track.draw(in: CGRect(x: 0, y: 0, width: 260, height: 14))
            }.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7))
            slider.setMinimumTrackImage(painted, for: .normal)
            slider.setMaximumTrackImage(painted, for: .normal)
        }
        if let knob = FruitfolioSliderArtwork.knob {
            let painted = UIGraphicsImageRenderer(size: CGSize(width: 36, height: 36)).image { _ in
                let scale = min(36 / knob.size.width, 36 / knob.size.height)
                let size = CGSize(width: knob.size.width * scale, height: knob.size.height * scale)
                knob.draw(in: CGRect(x: (36-size.width)/2, y: (36-size.height)/2, width: size.width, height: size.height))
            }
            slider.setThumbImage(painted, for: .normal)
            slider.setThumbImage(painted, for: .highlighted)
        }
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return slider
    }
    func updateUIView(_ slider: UISlider, context: Context) {
        context.coordinator.parent = self
        slider.value = Float(min(max(value, 0), 1))
        slider.accessibilityLabel = title
        slider.accessibilityIdentifier = "settings.volume." + title.replacingOccurrences(of: " ", with: "_")
        slider.semanticContentAttribute = direction == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
    }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISlider, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 260, height: 48)
    }
    final class Coordinator: NSObject {
        var parent: FruitfolioArtworkVolumeSlider
        init(_ parent: FruitfolioArtworkVolumeSlider) { self.parent = parent }
        @objc func changed(_ slider: UISlider) { parent.value = Double(slider.value) }
    }
}
