import SwiftUI

/// A single extensible founder-painted sheet behind the whole session, never
/// one paper image per answer. Its background travels with the scroll content.
struct Prompt09ContinuousPaper: View {
    var body: some View {
        GeometryReader { geometry in
            let metrics = Prompt09PaperLayout.metrics(viewport: geometry.size)
            Image("ask_answer_paper")
                .resizable(capInsets: EdgeInsets(top: 100, leading: 0, bottom: 100, trailing: 0), resizingMode: .stretch)
                .frame(width: Prompt09PaperLayout.paperPixels.width, height: metrics.sourceHeight)
                .scaleEffect(metrics.imageScale, anchor: .topLeading)
                .frame(width: metrics.paperWidth,
                       height: metrics.sourceHeight * metrics.imageScale, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .top)
                .accessibilityHidden(true)
        }
        .allowsHitTesting(false)
    }
}

/// Equal runtime columns reserve a text-free decoration area at the opening
/// paper anchor. Artwork is not duplicated on subsequent answers.
struct Prompt09OpeningFruitComposition: View {
    var body: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / 3
            HStack(spacing: 0) {
                fruit(.pear, width: cellWidth)
                fruit(.orangeSlice, width: cellWidth, rotation: 29)
                fruit(.orangeGlow, width: cellWidth)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: 120)
        .padding(.vertical, 12)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func fruit(_ artwork: Prompt09OpeningFruitArtwork, width: CGFloat, rotation: Double = 0) -> some View {
        let box = CGSize(width: max(0, width * 0.70), height: 80)
        let offset = artwork.opticalOffset(box: box)
        return Image(artwork.rawValue).resizable().scaledToFit()
            .frame(width: box.width, height: box.height)
            .offset(x: offset.width, y: offset.height)
            .rotationEffect(.degrees(rotation))
            .frame(width: width, height: 120)
    }
}
