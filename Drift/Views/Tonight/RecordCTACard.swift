import SwiftUI

struct RecordCTACard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.driftPurple.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.driftPurple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("What did you dream about last night?")
                        .font(.outfit(15, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Text("Dreams fade in minutes. Capture yours before it disappears.")
                        .font(.outfit(12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.driftPurple)
            }
            .padding(20)
            .background(Color.driftCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
