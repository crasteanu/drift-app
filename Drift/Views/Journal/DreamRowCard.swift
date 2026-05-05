import SwiftUI

struct DreamRowCard: View {
    let dream: Dream

    private var durationLabel: String {
        let d = dream.recordingDuration
        if d < 1 { return "" }
        let s = Int(d) % 60
        let m = Int(d) / 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient.driftTealPurple)
                .frame(width: 3)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(dream.emojis.prefix(3).joined())
                        .font(.system(size: 20))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(dream.vividness)")
                            .font(.outfit(16, weight: .bold))
                            .foregroundColor(.driftCoral)
                        Text("vivid")
                            .font(.outfit(9))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }

                Text(dream.title)
                    .font(.cormorant(19, weight: .semibold, italic: true))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack {
                    Text(dream.formattedDate)
                        .font(.outfit(12))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    if !durationLabel.isEmpty {
                        Label(durationLabel, systemImage: "waveform")
                            .font(.outfit(11))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                if !dream.snippet.isEmpty {
                    Text(dream.snippet)
                        .font(.outfit(13))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }

                TagChipRow(tags: dream.tags, max: 3)
            }
            .padding(16)
        }
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
