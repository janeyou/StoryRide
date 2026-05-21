import SwiftUI
import SwiftData

struct AllPlaylistsView: View {
    @EnvironmentObject var dropboxService: DropboxService
    @EnvironmentObject var audioPlayer: AudioPlayerService
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StoryFolder.sortOrder) private var folders: [StoryFolder]
    @AppStorage("playlistsLayout") private var playlistsLayout: String = "list"
    @State private var openPlaylist: StoryFolder?
    @State private var openPlayer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Color.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    DialTopBar(
                        eyebrow: "LIBRARY",
                        title: "All playlists",
                        onBack: { dismiss() }
                    ) {
                        DialIconButton(systemName: "magnifyingglass") { }
                    }

                    statChipRow
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 4)

                    content
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, audioPlayer.hasLoadedTrack ? 140 : 40)
                }
            }

            MiniPlayer(audioPlayer: audioPlayer) { openPlayer = true }
                .padding(.horizontal, 12)
                .padding(.bottom, 44)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .navigationDestination(item: $openPlaylist) { folder in
            PlaylistDetailView(folder: folder)
        }
        .navigationDestination(isPresented: $openPlayer) { PlayerView() }
    }

    private var totalStories: Int {
        folders.map { dropboxService.files(in: $0.dropboxPath).count }.reduce(0, +)
    }

    private var statChipRow: some View {
        HStack(spacing: 8) {
            statChip(label: "\(folders.count) playlists", accented: true)
            statChip(label: "\(totalStories) stories", accented: false)
            statChip(label: "A → Z", accented: false)
            Spacer(minLength: 0)
        }
    }

    private func statChip(label: String, accented: Bool) -> some View {
        Text(label)
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundColor(accented ? Theme.Color.accent : Theme.Color.inkSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(accented ? Theme.Color.accent.opacity(0.13) : Theme.Color.card)
            .overlay(
                Capsule().stroke(
                    accented ? Theme.Color.accent.opacity(0.27) : Theme.Color.border,
                    lineWidth: 1
                )
            )
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var content: some View {
        if playlistsLayout == "grid" {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(folders) { folder in
                    Button { openPlaylist = folder } label: {
                        gridTile(folder: folder)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            VStack(spacing: 0) {
                ForEach(Array(folders.enumerated()), id: \.element.dropboxPath) { idx, folder in
                    Button { openPlaylist = folder } label: {
                        listRow(folder: folder)
                    }
                    .buttonStyle(.plain)
                    if idx < folders.count - 1 {
                        Divider().background(Theme.Color.border)
                    }
                }
            }
        }
    }

    private func gridTile(folder: StoryFolder) -> some View {
        let count = dropboxService.files(in: folder.dropboxPath).count
        let visual = PlaylistVisual.make(from: folder.displayName)
        return VStack(alignment: .leading, spacing: 0) {
            PlaylistCover(visual: visual, cornerRadius: 12)
                .aspectRatio(1, contentMode: .fit)
            Text(folder.displayName)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.Color.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.top, 10)
            Text(count > 0 ? "\(count) stories" : "tap to load")
                .font(.system(size: 12.5, design: .rounded))
                .foregroundColor(Theme.Color.inkFaint)
                .padding(.top, 3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func listRow(folder: StoryFolder) -> some View {
        let count = dropboxService.files(in: folder.dropboxPath).count
        let visual = PlaylistVisual.make(from: folder.displayName)
        return HStack(spacing: 14) {
            PlaylistCover(visual: visual, cornerRadius: 12)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.displayName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Color.ink)
                    .lineLimit(1)
                Text(count > 0 ? "\(count) stories" : "tap to load")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Theme.Color.inkFaint)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Color.inkFaint)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
