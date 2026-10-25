import Foundation

enum FruitfolioAudioCategory: String, CaseIterable, Sendable {
    case music
    case rainAmbience
    case soundEffects
    case typingASMR
}

enum FruitfolioAudioID: String, CaseIterable, Sendable {
    case fruitBasketMusicbox = "audio_fruitbasket_musicbox"
    case fruitBasketRainAmbience = "audio_fruitbasket_rain"
    case fruitBasketRainObstacle = "audio_fruitbasket_rain_OBSTACLE"
    case fruitBasketWind = "audio_fruitbasket_wind_gust"
    case notificationSoftSparkle = "audio_notification"
    case buttonSoftPop = "audio_button_soft_pop"
    case popupOpen = "audio_popup_open"
    case popupClose = "audio_popup_close"
    case pageTurn = "audio_page_turn"
    case bookClose = "audio_book_close"
    case typingSoft = "audio_typing_soft"
    case gameCorrect = "audio_game_correct"
    case gameIncorrect = "audio_game_incorrect"
    case starChime = "audio_star_chime"
    case fruitCatch = "audio_fruit_catch"
    case vineRustle = "audio_vine_rustle"
    case gentleCheer = "audio_gentle_cheer"
    case errorSoft = "audio_error_soft"
    case bubblePop = "audio_bubble_pop"
}

struct FruitfolioAudioDescriptor: Hashable, Sendable {
    let id: FruitfolioAudioID
    let category: FruitfolioAudioCategory
    let perceivedVolume: ClosedRange<Double>
    let notes: String
}

enum FruitfolioAudioDesign {
    // This is design metadata only. Prompt 03 owns the centralized AudioManager/playback architecture.
    static let descriptors: [FruitfolioAudioID: FruitfolioAudioDescriptor] = [
        .fruitBasketMusicbox: .init(
            id: .fruitBasketMusicbox,
            category: .music,
            perceivedVolume: 0.20...0.45,
            notes: "soft instrumental music-box ambience; no vocals"
        ),

        .fruitBasketRainAmbience: .init(
            id: .fruitBasketRainAmbience,
            category: .rainAmbience,
            perceivedVolume: 0.15...0.25,
            notes: "toggleable background rain ambience layered under Fruit Basket music"
        ),

        .fruitBasketRainObstacle: .init(
            id: .fruitBasketRainObstacle,
            category: .soundEffects,
            perceivedVolume: 0.08...0.20,
            notes: "brief Fruit Basket rain obstacle sound; separate from toggleable rain ambience"
        ),

        .fruitBasketWind: .init(
            id: .fruitBasketWind,
            category: .soundEffects,
            perceivedVolume: 0.08...0.20,
            notes: "brief soft watercolor-world wind gust for breezy Fruit Basket weather"
        ),

        .notificationSoftSparkle: .init(
            id: .notificationSoftSparkle,
            category: .soundEffects,
            perceivedVolume: 0.06...0.16,
            notes: "reserved soft sparkle for future notification architecture; registered but not auto-played"
        ),

        .buttonSoftPop: .init(
            id: .buttonSoftPop,
            category: .soundEffects,
            perceivedVolume: 0.08...0.20,
            notes: "very soft rounded bup"
        ),

        .popupOpen: .init(
            id: .popupOpen,
            category: .soundEffects,
            perceivedVolume: 0.08...0.20,
            notes: "distinct tiny paper/water-bubble ploop"
        ),

        .popupClose: .init(
            id: .popupClose,
            category: .soundEffects,
            perceivedVolume: 0.08...0.20,
            notes: "soft popup dismissal sound"
        ),

        .pageTurn: .init(
            id: .pageTurn,
            category: .soundEffects,
            perceivedVolume: 0.08...0.22,
            notes: "soft paper fshhh"
        ),

        .bookClose: .init(
            id: .bookClose,
            category: .soundEffects,
            perceivedVolume: 0.08...0.22,
            notes: "soft clothbound fwump"
        ),

        .typingSoft: .init(
            id: .typingSoft,
            category: .typingASMR,
            perceivedVolume: 0.04...0.12,
            notes: "quiet dry tk with subtle variation"
        ),

        .gameCorrect: .init(
            id: .gameCorrect,
            category: .soundEffects,
            perceivedVolume: 0.08...0.22,
            notes: "small warm rising two-note chime"
        ),

        .gameIncorrect: .init(
            id: .gameIncorrect,
            category: .soundEffects,
            perceivedVolume: 0.08...0.20,
            notes: "gentle neutral descending wooden two-note sound; no buzzer"
        ),

        .starChime: .init(
            id: .starChime,
            category: .soundEffects,
            perceivedVolume: 0.05...0.16,
            notes: "delicate high soft cling"
        ),

        .fruitCatch: .init(
            id: .fruitCatch,
            category: .soundEffects,
            perceivedVolume: 0.06...0.18,
            notes: "quiet satisfying plup"
        ),

        .vineRustle: .init(
            id: .vineRustle,
            category: .soundEffects,
            perceivedVolume: 0.04...0.14,
            notes: "tiny leaf/brushing texture"
        ),

        .gentleCheer: .init(
            id: .gentleCheer,
            category: .soundEffects,
            perceivedVolume: 0.06...0.18,
            notes: "brief music-box flourish / very soft cheer"
        ),

        .errorSoft: .init(
            id: .errorSoft,
            category: .soundEffects,
            perceivedVolume: 0.06...0.18,
            notes: "gentle do…dum; never punitive"
        )
    ]
}
