import SwiftUI

struct TagChip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.outfit(12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

struct TagChipRow: View {
    let tags: [String]
    let max: Int?

    init(tags: [String], max: Int? = nil) {
        self.tags = tags
        self.max = max
    }

    var body: some View {
        FlowLayout(spacing: 6) {
            let displayed = max.map { Array(tags.prefix($0)) } ?? tags
            ForEach(Array(displayed.enumerated()), id: \.offset) { i, tag in
                TagChip(label: tag, color: tagColor(for: i))
            }
            if let m = max, tags.count > m {
                TagChip(label: "+\(tags.count - m)", color: .white.opacity(0.5))
            }
        }
    }
}

// Simple flow layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(width: proposal.width ?? UIScreen.main.bounds.width, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(width: bounds.width, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func layout(width maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                totalHeight = y
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight = y + rowHeight

        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}
