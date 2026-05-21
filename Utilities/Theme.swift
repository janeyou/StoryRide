import SwiftUI

// Palette derived from janeyoubradley.com/taste.md (dark-mode tokens),
// with a coral accent for the toddler-friendly twist.
enum Theme {
    enum Color {
        static let bg = SwiftUI.Color(red: 0x0e / 255, green: 0x0f / 255, blue: 0x13 / 255)
        static let bgElev = SwiftUI.Color(red: 0x16 / 255, green: 0x18 / 255, blue: 0x1e / 255)
        static let bgDim = SwiftUI.Color(red: 0x11 / 255, green: 0x13 / 255, blue: 0x1a / 255)
        static let text = SwiftUI.Color(red: 0xc8 / 255, green: 0xc8 / 255, blue: 0xc8 / 255)
        static let textStrong = SwiftUI.Color(red: 0xec / 255, green: 0xec / 255, blue: 0xec / 255)
        static let textMuted = SwiftUI.Color(red: 0x7a / 255, green: 0x7a / 255, blue: 0x7a / 255)
        static let textFaint = SwiftUI.Color(red: 0x4a / 255, green: 0x4a / 255, blue: 0x4a / 255)
        static let border = SwiftUI.Color(red: 0x23 / 255, green: 0x25 / 255, blue: 0x2d / 255)
        static let accent = SwiftUI.Color(red: 0xe0 / 255, green: 0x9b / 255, blue: 0x87 / 255)
        static let accentSoft = SwiftUI.Color(red: 0xe0 / 255, green: 0x9b / 255, blue: 0x87 / 255).opacity(0.12)
    }

    enum Radius {
        static let card: CGFloat = 12
        static let chip: CGFloat = 999
    }

    enum Font {
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func body(_ size: CGFloat = 17, weight: SwiftUI.Font.Weight = .light) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func label(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
    }
}
