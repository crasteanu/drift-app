import SwiftUI

private struct OnboardPage {
    let icon: String?
    let title: String
    let body: String
    let isLogo: Bool
}

private let pages: [OnboardPage] = [
    .init(icon: nil,
          title: "drift.",
          body: "Your dream life, interpreted. Every night holds a story — Drift helps you read it.",
          isLogo: true),
    .init(icon: "mic.fill",
          title: "Speak or type your dream",
          body: "Record your voice the moment you wake up. Drift transcribes every detail on-device — nothing leaves your phone.",
          isLogo: false),
    .init(icon: "sparkles",
          title: "AI reads the symbols",
          body: "Claude AI uncovers psychological depth and esoteric meaning from your words. Choose inner, esoteric, or both lenses.",
          isLogo: false),
    .init(icon: "chart.line.uptrend.xyaxis",
          title: "Patterns emerge over time",
          body: "Recurring symbols, emotional arcs, and threads across your dreamscape surface as you record more.",
          isLogo: false),
]

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var page = 0

    var body: some View {
        ZStack {
            Color.driftBackground.ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [Color.driftPurple.opacity(0.18), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageSlide(pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: page)

                bottomBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 52)
            }
        }
    }

    // MARK: - Page slide

    private func pageSlide(_ p: OnboardPage) -> some View {
        VStack(spacing: 0) {
            Spacer()

            if p.isLogo {
                logoSlide
            } else {
                featureSlide(p)
            }

            Spacer()

            Text(p.body)
                .font(.outfit(16))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 36)
                .padding(.bottom, 56)
        }
    }

    private var logoSlide: some View {
        VStack(spacing: 16) {
            Text("drift.")
                .font(.cormorant(80, weight: .bold, italic: true))
                .foregroundStyle(LinearGradient.driftTealPurple)

            Text("dream journal")
                .font(.outfit(15, weight: .light))
                .foregroundColor(.white.opacity(0.35))
                .tracking(4)
        }
        .padding(.bottom, 40)
    }

    private func featureSlide(_ p: OnboardPage) -> some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.driftPurple.opacity(0.12))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(Color.driftPurple.opacity(0.25), lineWidth: 1)
                    .frame(width: 120, height: 120)
                if let icon = p.icon {
                    Image(systemName: icon)
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(LinearGradient.driftTealPurple)
                }
            }

            Text(p.title)
                .font(.cormorant(36, weight: .bold, italic: true))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 36)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 28) {
            // Dot indicators
            HStack(spacing: 7) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color.driftPurple : Color.white.opacity(0.2))
                        .frame(width: i == page ? 22 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                }
            }

            if page == pages.count - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { hasSeenWelcome = true }
                } label: {
                    Text("Begin Your Journey")
                        .font(.outfit(17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.driftPurple, .driftPurpleDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                HStack {
                    Button("Skip") {
                        withAnimation(.easeInOut(duration: 0.3)) { hasSeenWelcome = true }
                    }
                    .font(.outfit(14))
                    .foregroundColor(.white.opacity(0.35))

                    Spacer()

                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.outfit(15, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.driftPurple)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
