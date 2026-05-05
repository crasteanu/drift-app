import SwiftUI

extension Color {
    static let driftBackground    = Color(hex: "#000000")
    static let driftPurple        = Color(hex: "#5B4FE8")
    static let driftPurpleDark    = Color(hex: "#3B2FA8")
    static let driftNavy          = Color(hex: "#1A1560")
    static let driftCard          = Color(hex: "#1E1B4B")
    static let driftTeal          = Color(hex: "#4DD9C0")
    static let driftCoral         = Color(hex: "#FF6B6B")
    static let driftAmber         = Color(hex: "#F59E0B")
    static let driftTagTeal       = Color(hex: "#4DD9C0")
    static let driftTagGreen      = Color(hex: "#22C55E")
    static let driftTagPink       = Color(hex: "#EC4899")
    static let driftTagPurple     = Color(hex: "#8B5CF6")
    static let driftTagAmber      = Color(hex: "#F59E0B")
    static let driftTagBrown      = Color(hex: "#78716C")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

extension LinearGradient {
    static let driftTealPurple = LinearGradient(
        colors: [.driftTeal, .driftPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let driftPurplePink = LinearGradient(
        colors: [.driftTagPurple, .driftTagPink],
        startPoint: .leading,
        endPoint: .trailing
    )
}

let tagColorPalette: [Color] = [
    .driftTagTeal, .driftTagGreen, .driftTagPink,
    .driftTagPurple, .driftTagAmber, .driftTagBrown, .white
]

func tagColor(for index: Int) -> Color {
    tagColorPalette[index % tagColorPalette.count]
}
