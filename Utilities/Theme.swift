import SwiftUI

// Design tokens for the RideStory revamp.
// Reference: design_handoff_rideStory_revamp/README.md
enum Theme {
    enum Color {
        // ── Surfaces ────────────────────────────────────────────────
        static let bg        = hex(0x0a0a0c)
        static let card      = hex(0x15151a)
        static let cardElev  = hex(0x1c1c22)
        static let chip      = hex(0x1f1f25)
        static let border    = SwiftUI.Color.white.opacity(0.07)

        // ── Ink (text) ──────────────────────────────────────────────
        static let ink       = hex(0xf5f1ea)
        static let inkSoft   = hex(0xcfc7b8)
        static let inkFaint  = hex(0x8a8270)

        // ── Accent (honey by default; user-selectable in Settings later) ──
        static let accent    = hex(0xffd166)
        static let accentFg  = bg                 // text/glyph color on top of accent

        // ── Back-compat aliases for older views still on the old names ──
        static let bgElev      = card
        static let bgDim       = card
        static let text        = inkSoft
        static let textStrong  = ink
        static let textMuted   = inkFaint
        static let textFaint   = inkFaint
        static let accentSoft  = accent.opacity(0.13)

        private static func hex(_ value: Int) -> SwiftUI.Color {
            SwiftUI.Color(
                red: Double((value >> 16) & 0xff) / 255,
                green: Double((value >> 8) & 0xff) / 255,
                blue: Double(value & 0xff) / 255
            )
        }
    }

    enum Radius {
        static let tile: CGFloat = 28          // now-playing tile
        static let playerCover: CGFloat = 24
        static let detailCover: CGFloat = 20
        static let card: CGFloat = 16
        static let mini: CGFloat = 18
        static let chip: CGFloat = 999
    }

    enum Font {
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func body(_ size: CGFloat = 17, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func label(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
    }
}
