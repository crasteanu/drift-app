import SwiftUI
import SwiftData

struct YearInDreamsTeaser: View {
    @Query private var dreams: [Dream]
    let onTap: () -> Void

    private var thisYearCount: Int {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        return dreams.filter { cal.component(.year, from: $0.date) == year }.count
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Year in Dreams")
                        .font(.outfit(15, weight: .semibold))
                        .foregroundColor(.driftAmber)
                    Text("\(thisYearCount) dreams captured this year")
                        .font(.outfit(13))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.driftAmber)
            }
            .padding(20)
            .background(Color.driftCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.driftAmber.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
