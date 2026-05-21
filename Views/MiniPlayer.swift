import SwiftUI

/// Floating now-playing bar. Visible on Home / AllPlaylists / PlaylistDetail when a
/// track is loaded. Tapping the bar opens the full PlayerView; the play button toggles
/// playback in place.
struct MiniPlayer: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    let onOpen: () -> Void

    var body: some View {
        if let file = audioPlayer.currentFile {
            content(file: file)
        }
    }

    private func content(file: DropboxFile) -> some View {
        let visual = PlaylistVisual.make(from: playlistName)
        let progress = audioPlayer.duration > 0 ? audioPlayer.currentTime / audioPlayer.duration : 0
        let remaining = max(audioPlayer.duration - audioPlayer.currentTime, 0)

        return Button(action: onOpen) {
            HStack(spacing: 12) {
                StoryCover(playlist: visual, storyTitle: file.displayTitle, cornerRadius: 11)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 1) {
                    Text(file.displayTitle)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Color.ink)
                        .lineLimit(1)
                    Text("\(playlistName) · \(formatTime(remaining)) left")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Theme.Color.ink.opacity(0.7))
                        .lineLimit(1)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                                .frame(height: 2)
                            Capsule()
                                .fill(Theme.Color.accent)
                                .frame(width: proxy.size.width * progress, height: 2)
                        }
                    }
                    .frame(height: 2)
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    audioPlayer.togglePlayPause()
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Color.accentFg)
                        .frame(width: 44, height: 44)
                        .background(Theme.Color.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(height: 64)
            .background(
                ZStack {
                    Color.black.opacity(0.55)
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.mini, style: .continuous)
                    .stroke(Theme.Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.mini, style: .continuous))
            .shadow(color: .black.opacity(0.55), radius: 16, x: 0, y: 12)
        }
        .buttonStyle(.plain)
    }

    private var playlistName: String {
        guard let path = audioPlayer.currentPlaylistPath else { return "" }
        let name = (path as NSString).lastPathComponent
        return name.isEmpty ? "/" : name
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }
}
