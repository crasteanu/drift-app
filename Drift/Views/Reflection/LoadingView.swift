import SwiftUI

struct LoadingView: View {
    @State private var messageIndex = 0
    @State private var dotCount = 0
    @State private var orbScale: CGFloat = 1.0
    @State private var dotTimer: Timer?
    @State private var messageTimer: Timer?

    private let messages = [
        "Drifting through your dream...",
        "Finding hidden threads...",
        "Tracing the emotional current...",
        "Reading between the images...",
        "Mapping recurring patterns..."
    ]

    var body: some View {
        ZStack {
            Color.driftBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Pulsating teal orb
                ZStack {
                    ForEach([0, 1, 2], id: \.self) { i in
                        Circle()
                            .stroke(Color.driftTeal.opacity(0.2 - Double(i) * 0.05), lineWidth: 1)
                            .frame(width: CGFloat(100 + i * 30), height: CGFloat(100 + i * 30))
                            .scaleEffect(orbScale)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(Double(i) * 0.3), value: orbScale)
                    }

                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.driftTeal.opacity(0.8), Color.driftPurple],
                            center: .topLeading,
                            startRadius: 10,
                            endRadius: 60
                        ))
                        .frame(width: 90, height: 90)
                        .scaleEffect(orbScale)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: orbScale)
                        .shadow(color: Color.driftTeal.opacity(0.5), radius: 20)

                    Text("🌙✦")
                        .font(.system(size: 28))
                }

                // Cycling message
                Text(messages[messageIndex])
                    .font(.cormorant(22, italic: true))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .id(messageIndex)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: messageIndex)

                // 3 dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.driftPurple)
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotCount == i ? 1.4 : 0.8)
                            .animation(.easeInOut(duration: 0.4), value: dotCount)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            orbScale = 1.08
            startCycling()
        }
        .onDisappear {
            dotTimer?.invalidate()
            messageTimer?.invalidate()
            dotTimer = nil
            messageTimer = nil
        }
    }

    private func startCycling() {
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation { dotCount = (dotCount + 1) % 3 }
        }
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation { messageIndex = (messageIndex + 1) % messages.count }
        }
    }
}
