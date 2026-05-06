import SwiftUI
import SwiftData

struct MoonPhaseCard: View {
    @Query private var dreams: [Dream]

    private var phase: MoonPhase { MoonPhaseService.phase() }
    private var streak: Int { PatternEngine.streak(from: dreams) }
    private var lastNightCount: Int {
        let cal = Calendar.current
        let yesterday = cal.startOfDay(for: cal.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        // Include early-morning same-day recordings up to noon — a 7am entry is still "last night"
        let cutoff = cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? cal.startOfDay(for: Date())
        return dreams.filter { $0.date >= yesterday && $0.date < cutoff }.count
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: moon + name + date
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(phase.emoji)
                        .font(.system(size: 28))
                    Text(phase.name)
                        .font(.outfit(16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(MoonPhaseService.formattedDate())
                    .font(.outfit(13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Center: streak
            VStack(spacing: 2) {
                if streak == 0 {
                    Text("Start tonight")
                        .font(.outfit(13))
                        .foregroundColor(.driftAmber)
                } else {
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(streak)")
                            .font(.outfit(20, weight: .bold))
                            .foregroundColor(.driftAmber)
                    }
                    Text(streak == 1 ? "day" : "days")
                        .font(.outfit(11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            // Right: last night count
            VStack(spacing: 2) {
                Text(lastNightCount == 0 ? "—" : "\(lastNightCount)")
                    .font(.outfit(20, weight: .bold))
                    .foregroundColor(.white)
                Text("last night")
                    .font(.outfit(11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(20)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
