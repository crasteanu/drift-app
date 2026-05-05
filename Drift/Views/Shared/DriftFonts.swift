import SwiftUI

// Custom font wrappers — Cormorant Garamond + Outfit, embedded in Resources/Fonts/.
extension Font {
    // Cormorant Garamond — display serif
    static func cormorant(_ size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        let name: String
        switch weight {
        case .bold:
            name = italic ? "CormorantGaramond-BoldItalic" : "CormorantGaramond-Bold"
        case .semibold:
            name = italic ? "CormorantGaramond-SemiBoldItalic" : "CormorantGaramond-SemiBold"
        default:
            name = italic ? "CormorantGaramond-Italic" : "CormorantGaramond-Regular"
        }
        return Font.custom(name, size: size)
    }

    // Outfit — UI sans-serif
    static func outfit(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold:     name = "Outfit-Bold"
        case .semibold: name = "Outfit-SemiBold"
        case .medium:   name = "Outfit-Medium"
        case .light:    name = "Outfit-Light"
        default:        name = "Outfit-Regular"
        }
        return Font.custom(name, size: size)
    }
}
