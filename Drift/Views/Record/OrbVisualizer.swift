import SwiftUI

struct OrbVisualizer: View {
    let audioLevel: Float
    let isRecording: Bool
    let onTap: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer rings
                ForEach([1, 2, 3], id: \.self) { i in
                    Circle()
                        .stroke(Color.driftPurple.opacity(isRecording ? Double(4 - i) * 0.15 : 0.12), lineWidth: 1.5)
                        .frame(width: ringSize(i), height: ringSize(i))
                        .scaleEffect(isRecording ? 1 + CGFloat(audioLevel) * 0.08 * CGFloat(i) : (pulse ? 1.02 : 1.0))
                        .animation(
                            isRecording
                                ? .easeOut(duration: 0.1)
                                : .easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(Double(i) * 0.3),
                            value: isRecording ? audioLevel : (pulse ? Float(1) : Float(0))
                        )
                }

                // Core orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.driftPurple, Color.driftPurpleDark],
                            center: .topLeading,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.driftPurple.opacity(0.6), radius: isRecording ? 20 + CGFloat(audioLevel) * 20 : 12)
                    .scaleEffect(isRecording ? 1 + CGFloat(audioLevel) * 0.12 : (pulse ? 1.03 : 1.0))
                    .animation(isRecording ? .easeOut(duration: 0.1) : .easeInOut(duration: 2).repeatForever(autoreverses: true), value: isRecording ? audioLevel : (pulse ? Float(1) : Float(0)))

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
    }

    private func ringSize(_ index: Int) -> CGFloat {
        CGFloat(100 + index * 34)
    }
}

