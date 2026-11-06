#if DEBUG
import SwiftUI

/// Opt-in QA only. Requests and AVAudioPlayer.play() success are distinct from
/// physical audibility/volume/listening validation. No health input is recorded.
struct FruitfolioInteractionSoundDiagnostics: View {
    @EnvironmentObject private var audio: AudioManager
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            counter("soft pop requests", .buttonSoftPop, starts: false, id: "audioQA.softPopRequests")
            counter("soft pop starts", .buttonSoftPop, starts: true, id: "audioQA.softPopStarts")
            counter("star chime requests", .starChime, starts: false, id: "audioQA.starChimeRequests")
            counter("gentle cheer requests", .gentleCheer, starts: false, id: "audioQA.cheerRequests")
            counter("popup open requests", .popupOpen, starts: false, id: "audioQA.openRequests")
            counter("popup close requests", .popupClose, starts: false, id: "audioQA.closeRequests")
        }
        .font(.caption2)
        .padding(4)
        .background(.regularMaterial)
        .allowsHitTesting(false)
    }
    private func counter(_ label: String, _ cue: FruitfolioAudioID, starts: Bool, id: String) -> some View {
        let count = starts ? audio.debugInteractionPlaybackStarts[cue.rawValue, default: 0]
                           : audio.debugInteractionRequests[cue.rawValue, default: 0]
        return Text("\(label): \(count)").accessibilityIdentifier(id)
    }
}
#endif
