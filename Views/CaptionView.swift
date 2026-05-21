import SwiftUI

struct CaptionView: View {
    let words: [CaptionWord]
    @AppStorage("captionFontSize") private var captionFontSize: Double = 48

    var body: some View {
        VStack {
            Spacer()

            FlowLayout(spacing: 8) {
                ForEach(words) { word in
                    Text(word.text)
                        .font(.system(size: captionFontSize, weight: word.isActive ? .medium : .light, design: .rounded))
                        .foregroundColor(word.isActive ? Theme.Color.accent : Theme.Color.text)
                        .animation(.easeInOut(duration: 0.2), value: word.isActive)
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }

        return LayoutResult(
            positions: positions,
            size: CGSize(width: maxWidth, height: y + lineHeight)
        )
    }

    private struct LayoutResult {
        let positions: [CGPoint]
        let size: CGSize
    }
}
