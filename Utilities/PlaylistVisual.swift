import SwiftUI

// Procedural cover art for playlists. Derives a deterministic gradient + motif
// from the playlist's display name (keyword match → fallback to stable hash).
// Reference: design_handoff_rideStory_revamp/README.md "Playlist gradient palette".

enum PlaylistMotif: String, CaseIterable {
    case moon, sun, leaf, wave, rings, arc
}

struct PlaylistVisual {
    let accentA: Color   // dark stop
    let accentB: Color   // light stop
    let motif: PlaylistMotif

    static func make(from name: String) -> PlaylistVisual {
        let lower = name.lowercased()
        for entry in keywordTable {
            if entry.keywords.contains(where: { lower.contains($0) }) {
                return entry.visual
            }
        }
        // Fallback: derive a hue from a stable hash → 360 distinct gradients.
        // Swift's `hashValue` is randomized per launch, so we roll our own (FNV-1a 64).
        let h = stableHash(name)
        let hue = Double(h % 360) / 360.0
        let motif = PlaylistMotif.allCases[Int(h % UInt64(PlaylistMotif.allCases.count))]
        return PlaylistVisual(
            accentA: Color(hue: hue, saturation: 0.55, brightness: 0.32),
            accentB: Color(hue: hue, saturation: 0.55, brightness: 0.62),
            motif: motif
        )
    }

    /// FNV-1a 64-bit. Stable across launches, unlike `Swift.hashValue`.
    static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in s.utf8 {
            h ^= UInt64(byte)
            h = h &* 0x100_0000_01b3
        }
        return h
    }

    private struct Entry { let keywords: [String]; let visual: PlaylistVisual }

    private static let keywordTable: [Entry] = [
        Entry(keywords: ["bedtime", "night", "sleep"],
              visual: .init(accentA: hex(0x1f2a55), accentB: hex(0x3a4d96), motif: .moon)),
        Entry(keywords: ["morning", "wake", "curious"],
              visual: .init(accentA: hex(0xc25a2d), accentB: hex(0xf3a35a), motif: .sun)),
        Entry(keywords: ["animal", "creature", "zoo"],
              visual: .init(accentA: hex(0x1f5238), accentB: hex(0x3f8c5b), motif: .leaf)),
        Entry(keywords: ["lullaby", "lullabies", "soft"],
              visual: .init(accentA: hex(0x3a2456), accentB: hex(0x7e5da6), motif: .wave)),
        Entry(keywords: ["imagination", "made-up", "made up", "fantasy", "dream"],
              visual: .init(accentA: hex(0x7a2549), accentB: hex(0xc46d8a), motif: .rings)),
        Entry(keywords: ["adventure", "journey", "tiny"],
              visual: .init(accentA: hex(0x1f4a59), accentB: hex(0x4a8aa3), motif: .arc)),
        Entry(keywords: ["garden", "nature", "outside"],
              visual: .init(accentA: hex(0x3d5a1f), accentB: hex(0x7ea24b), motif: .leaf)),
        Entry(keywords: ["friend", "feeling", "feelings"],
              visual: .init(accentA: hex(0x7a5a1c), accentB: hex(0xd4a44a), motif: .sun)),
    ]

    private static func hex(_ value: Int) -> Color {
        Color(
            red: Double((value >> 16) & 0xff) / 255,
            green: Double((value >> 8) & 0xff) / 255,
            blue: Double(value & 0xff) / 255
        )
    }
}

struct PlaylistCover: View {
    let visual: PlaylistVisual
    var cornerRadius: CGFloat = 12

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [visual.accentB, visual.accentA],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { proxy in
                motifShape(in: proxy.size)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private func motifShape(in size: CGSize) -> some View {
        let w = size.width
        let h = size.height
        switch visual.motif {
        case .moon:
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: w * 0.28, height: w * 0.28)
                    .position(x: w * 0.72, y: h * 0.28)
                Circle()
                    .fill(visual.accentA)
                    .frame(width: w * 0.26, height: w * 0.26)
                    .position(x: w * 0.68, y: h * 0.26)
            }
        case .sun:
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: w * 0.76, height: w * 0.76)
                .position(x: w * 0.5, y: h * 0.7)
        case .leaf:
            ZStack {
                LeafShape()
                    .fill(Color.white.opacity(0.35))
                Rectangle()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: 1.5, height: h * 0.62)
                    .position(x: w * 0.5, y: h * 0.5)
            }
        case .wave:
            ZStack {
                WaveShape(yOffset: 0.6)
                    .fill(Color.white.opacity(0.30))
                WaveShape(yOffset: 0.75)
                    .fill(Color.white.opacity(0.25))
            }
        case .rings:
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.40), lineWidth: max(2, w * 0.03))
                    .frame(width: w * 0.76, height: w * 0.76)
                Circle()
                    .stroke(Color.white.opacity(0.45), lineWidth: max(2, w * 0.03))
                    .frame(width: w * 0.48, height: w * 0.48)
                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: w * 0.2, height: w * 0.2)
            }
        case .arc:
            ZStack {
                ArcShape(radius: 0.6)
                    .stroke(Color.white.opacity(0.45), lineWidth: max(3, w * 0.06))
                ArcShape(radius: 0.4)
                    .stroke(Color.white.opacity(0.35), lineWidth: max(3, w * 0.05))
            }
        }
    }
}

/// A story-level cover. Keeps the playlist's gradient (so the playlist's identity is
/// preserved) but picks the motif from the story title's stable hash so different
/// stories within one playlist render distinctly in Favorites / Recents / MiniPlayer.
struct StoryCover: View {
    let playlist: PlaylistVisual
    let storyTitle: String
    var cornerRadius: CGFloat = 12

    var body: some View {
        let motif = PlaylistMotif.allCases[
            Int(PlaylistVisual.stableHash(storyTitle) % UInt64(PlaylistMotif.allCases.count))
        ]
        PlaylistCover(
            visual: PlaylistVisual(accentA: playlist.accentA, accentB: playlist.accentB, motif: motif),
            cornerRadius: cornerRadius
        )
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.2, y: h * 0.8))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.8, y: h * 0.8),
            control: CGPoint(x: w * 0.5, y: -h * 0.1)
        )
        p.closeSubpath()
        return p
    }
}

private struct WaveShape: Shape {
    let yOffset: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let baseY = h * yOffset
        p.move(to: CGPoint(x: 0, y: baseY))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: baseY),
            control: CGPoint(x: w * 0.25, y: baseY - h * 0.2)
        )
        p.addQuadCurve(
            to: CGPoint(x: w, y: baseY),
            control: CGPoint(x: w * 0.75, y: baseY + h * 0.2)
        )
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

private struct ArcShape: Shape {
    /// Radius as a fraction of the shorter axis.
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * radius
        let center = CGPoint(x: rect.midX, y: rect.height * 0.9)
        p.addArc(
            center: center,
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(360),
            clockwise: false
        )
        return p
    }
}
