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

struct FruitfolioArtworkVolumeSlider: View {
    let title: String
    @Binding var value: Double
    @Environment(\.layoutDirection) private var direction
    private let knobWidth: CGFloat = 36
    private var identifier: String { "settings.volume." + title.replacingOccurrences(of: " ", with: "_") }

    var body: some View {
        GeometryReader { geometry in
            let width = max(knobWidth + 1, geometry.size.width)
            let travel = width - knobWidth
            let fraction = CGFloat(min(max(value, 0), 1))
            let visual = direction == .rightToLeft ? 1 - fraction : fraction
            ZStack {
                if let track = FruitfolioSliderArtwork.track {
                    Image(uiImage: track).resizable().scaledToFit()
                        .frame(width: travel).position(x: width / 2, y: 24)
                }
                if let knob = FruitfolioSliderArtwork.knob {
                    Image(uiImage: knob).resizable().scaledToFit()
                        .frame(width: knobWidth, height: knobWidth)
                        .position(x: knobWidth / 2 + visual * travel, y: 24)
                }
            }
            .frame(width: width, height: 48)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { event in
                let position = min(max((event.location.x - knobWidth / 2) / travel, 0), 1)
                value = Double(direction == .rightToLeft ? 1 - position : position)
            })
        }
        .frame(height: 48)
        .accessibilityRepresentation {
            Slider(value: $value, in: 0...1, step: 0.01)
                .accessibilityLabel(Text(title))
                .accessibilityValue("\(Int((min(max(value, 0), 1) * 100).rounded())) percent")
                .accessibilityIdentifier(identifier)
        }
    }
}
