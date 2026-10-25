import Foundation

struct FruitfolioRGB: Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255.0
        green = Double((hex >> 8) & 0xFF) / 255.0
        blue = Double(hex & 0xFF) / 255.0
    }
}

enum FruitfolioContrast {
    static func relativeLuminance(_ color: FruitfolioRGB) -> Double {
        func convert(_ value: Double) -> Double {
            value <= 0.04045
                ? value / 12.92
                : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * convert(color.red)
             + 0.7152 * convert(color.green)
             + 0.0722 * convert(color.blue)
    }

    static func ratio(_ first: FruitfolioRGB, _ second: FruitfolioRGB) -> Double {
        let a = relativeLuminance(first)
        let b = relativeLuminance(second)
        let lighter = max(a, b)
        let darker = min(a, b)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static let primaryBurgundy = FruitfolioRGB(hex: 0x6F273D)
    static let cream = FruitfolioRGB(hex: 0xFFF9F0)
    static let mint = FruitfolioRGB(hex: 0xCBDAC3)
    static let sage = FruitfolioRGB(hex: 0xE2DEAF)
    static let peach = FruitfolioRGB(hex: 0xFEDF9C)
    static let coral = FruitfolioRGB(hex: 0xFDAC9F)
    static let yellow = FruitfolioRGB(hex: 0xFEF0AD)
    static let lavender = FruitfolioRGB(hex: 0xF1CDF4)
    static let dustyBlue = FruitfolioRGB(hex: 0xB8CBD5)
}
