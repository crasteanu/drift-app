import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.driftBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        section(title: "What stays on your device (always)") {
                            Text("All recordings, transcripts, journal entries, symbols, patterns, and settings. Nothing is uploaded without your action.")
                        }

                        section(title: "What leaves your device (only when you interpret)") {
                            Text("Your dream transcript text is sent to Anthropic's Claude AI to generate your interpretation. This happens only when you tap interpret. It is not linked to any identity.")
                        }

                        section(title: "Payment") {
                            Text("Handled entirely by Apple via StoreKit. Drift never sees your payment details.")
                        }

                        section(title: "Your control") {
                            Text("You can export or delete everything from the Settings screen at any time.")
                        }

                        Text("Version 1.0 · Drift")
                            .font(.outfit(12))
                            .foregroundColor(.white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.driftPurple)
                }
            }
        }
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.outfit(14, weight: .semibold))
                .foregroundColor(.driftTeal)
            content()
                .font(.outfit(14))
                .foregroundColor(.white.opacity(0.75))
        }
    }
}
