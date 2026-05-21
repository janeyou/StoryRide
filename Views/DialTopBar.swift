import SwiftUI

/// Shared top bar for revamp sub-screens. Back button (optional) + eyebrow + title + trailing action.
struct DialTopBar<TrailingAction: View>: View {
    let eyebrow: String
    let title: String
    let eyebrowColor: Color
    var onBack: (() -> Void)?
    @ViewBuilder var trailingAction: () -> TrailingAction

    init(
        eyebrow: String,
        title: String,
        eyebrowColor: Color = Theme.Color.accent,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailingAction: @escaping () -> TrailingAction = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.eyebrowColor = eyebrowColor
        self.onBack = onBack
        self.trailingAction = trailingAction
    }

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Color.ink)
                        .frame(width: 44, height: 44)
                        .background(Theme.Color.card)
                        .overlay(
                            Circle().stroke(Theme.Color.border, lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundColor(eyebrowColor)
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .tracking(-0.3)
                        .foregroundColor(Theme.Color.ink)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailingAction()
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .padding(.bottom, 8)
    }
}

/// Reusable 44pt circular icon button (`card` fill, hairline border).
struct DialIconButton: View {
    let systemName: String
    let action: () -> Void
    var foreground: Color = Theme.Color.ink
    var background: Color = Theme.Color.card

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(foreground)
                .frame(width: 44, height: 44)
                .background(background)
                .overlay(Circle().stroke(Theme.Color.border, lineWidth: 1))
                .clipShape(Circle())
        }
    }
}
