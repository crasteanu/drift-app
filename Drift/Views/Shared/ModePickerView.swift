import SwiftUI

enum InterpretationMode: String, CaseIterable {
    case inner    = "inner"
    case esoteric = "esoteric"
    case both     = "both"

    var label: String {
        switch self {
        case .inner:    return "🧠 Inner"
        case .esoteric: return "🔮 Esoteric"
        case .both:     return "✨ Both"
        }
    }
}

struct ModePickerView: View {
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(InterpretationMode.allCases, id: \.self) { m in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = m.rawValue }
                } label: {
                    Text(m.label)
                        .font(.outfit(13, weight: selected == m.rawValue ? .semibold : .regular))
                        .foregroundColor(selected == m.rawValue ? .white : .white.opacity(0.45))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(selected == m.rawValue ? Color.driftPurple : Color.driftCard)
                        .clipShape(Capsule())
                        .overlay {
                            if selected != m.rawValue {
                                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
