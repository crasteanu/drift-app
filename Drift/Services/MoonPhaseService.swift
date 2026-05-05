import Foundation

struct MoonPhase {
    let name: String
    let emoji: String
    let illumination: Double // 0–1
}

enum MoonPhaseService {
    static func phase(for date: Date = Date()) -> MoonPhase {
        // Known new moon reference: Jan 6, 2000 18:14 UTC
        let referenceNewMoon = Date(timeIntervalSince1970: 947182440)
        let synodicMonth: TimeInterval = 29.53058867 * 86400

        let elapsed = date.timeIntervalSince(referenceNewMoon)
        var cycle = elapsed.truncatingRemainder(dividingBy: synodicMonth)
        if cycle < 0 { cycle += synodicMonth }

        let fraction = cycle / synodicMonth

        let illumination = (1 - cos(fraction * 2 * .pi)) / 2

        let (name, emoji): (String, String)
        switch fraction {
        case 0..<0.033:  (name, emoji) = ("New Moon", "🌑")
        case 0.033..<0.133: (name, emoji) = ("Waxing Crescent", "🌒")
        case 0.133..<0.241: (name, emoji) = ("First Quarter", "🌓")
        case 0.241..<0.367: (name, emoji) = ("Waxing Gibbous", "🌔")
        case 0.367..<0.5:   (name, emoji) = ("Full Moon", "🌕")
        case 0.5..<0.634:   (name, emoji) = ("Waning Gibbous", "🌖")
        case 0.634..<0.741: (name, emoji) = ("Last Quarter", "🌗")
        case 0.741..<0.966: (name, emoji) = ("Waning Crescent", "🌘")
        default:             (name, emoji) = ("New Moon", "🌑")
        }

        return MoonPhase(name: name, emoji: emoji, illumination: illumination)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, dd. MMM"
        return f
    }()

    static func formattedDate(_ date: Date = Date()) -> String {
        dateFormatter.string(from: date)
    }
}
