import SwiftUI

struct ControlsView: View {
    let isPlaying: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onPlayPause: () -> Void
    let onSkipBack: () -> Void
    let onSkipForward: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            progressBar

            HStack(spacing: 40) {
                skipButton(systemName: "gobackward.15", action: onSkipBack)
                    .frame(width: 80, height: 80)

                playPauseButton
                    .frame(width: 120, height: 120)

                skipButton(systemName: "goforward.15", action: onSkipForward)
                    .frame(width: 80, height: 80)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Color.border)
                        .frame(height: 4)

                    Capsule()
                        .fill(Theme.Color.accent)
                        .frame(width: duration > 0 ? geo.size.width * (currentTime / duration) : 0, height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                Text(formatTime(currentTime))
                Spacer()
                Text(formatTime(duration))
            }
            .font(Theme.Font.label(12))
            .foregroundColor(Theme.Color.textMuted)
        }
    }

    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundColor(Theme.Color.bg)
                .frame(width: 120, height: 120)
                .background(Theme.Color.accent)
                .clipShape(Circle())
        }
    }

    private func skipButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 26, weight: .light))
                .foregroundColor(Theme.Color.textStrong)
                .frame(width: 80, height: 80)
                .background(Theme.Color.bgElev)
                .clipShape(Circle())
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
