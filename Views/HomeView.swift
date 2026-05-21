import SwiftUI
import SwiftData

/// Driver-mode home screen. Replaces the old LibraryView pager.
struct HomeView: View {
    @EnvironmentObject var dropboxService: DropboxService
    @EnvironmentObject var audioPlayer: AudioPlayerService
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \StoryFolder.sortOrder) private var folders: [StoryFolder]
    @Query(sort: \StoryRecord.lastPlayedAt, order: .reverse) private var recents: [StoryRecord]
    @Query(filter: #Predicate<StoryRecord> { $0.isStarred }) private var favorites: [StoryRecord]

    @AppStorage("lastPlayedStoryId") private var lastPlayedStoryId: String = ""
    @AppStorage("playlistsLayout") private var playlistsLayout: String = "list"

    @State private var openSettings = false
    @State private var openAllPlaylists = false
    @State private var openPlayer = false
    @State private var openPlaylist: StoryFolder?
    @State private var showDiscover = false
    @State private var showAddFolder = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Theme.Color.bg.ignoresSafeArea()

                if folders.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            header
                            nowPlayingTile
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            favoritesSection
                            allPlaylistsSection
                            recentlyPlayedSection
                            Color.clear.frame(height: 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .navigationDestination(isPresented: $openSettings) { SettingsView() }
            .navigationDestination(isPresented: $openAllPlaylists) { AllPlaylistsView() }
            .navigationDestination(isPresented: $openPlayer) { PlayerView() }
            .navigationDestination(item: $openPlaylist) { folder in
                PlaylistDetailView(folder: folder)
            }
            .sheet(isPresented: $showDiscover) {
                DiscoverFoldersSheet().environmentObject(dropboxService)
            }
            .sheet(isPresented: $showAddFolder) {
                AddFolderSheet { name, path in
                    let order = (folders.last?.sortOrder ?? -1) + 1
                    modelContext.insert(StoryFolder(dropboxPath: path, displayName: name, sortOrder: order))
                    try? modelContext.save()
                }
                .environmentObject(dropboxService)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "car.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("DRIVER MODE")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.3)
            }
            .foregroundColor(Theme.Color.accent)

            Spacer()

            Button { openSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Color.ink)
                    .frame(width: 40, height: 40)
                    .background(Theme.Color.chip)
                    .overlay(Circle().stroke(Theme.Color.border, lineWidth: 1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 50)
        .padding(.bottom, 4)
    }

    // MARK: - Now Playing

    @ViewBuilder
    private var nowPlayingTile: some View {
        if let file = audioPlayer.currentFile {
            nowPlayingContent(file: file, playlistName: playlistName(for: audioPlayer.currentPlaylistPath))
        } else if let record = continueRecord() {
            // No live track loaded yet; show last-played as a resume hint.
            nowPlayingResume(record: record)
        } else {
            EmptyView()
        }
    }

    private func nowPlayingContent(file: DropboxFile, playlistName: String) -> some View {
        let visual = PlaylistVisual.make(from: playlistName)
        let progress = audioPlayer.duration > 0 ? audioPlayer.currentTime / audioPlayer.duration : 0
        let remaining = max(audioPlayer.duration - audioPlayer.currentTime, 0)

        return Button { openPlayer = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("NOW PLAYING")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .opacity(0.85)
                    Spacer()
                    ccPill
                }

                Text(file.displayTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.5)
                    .lineLimit(2)
                    .padding(.top, 16)

                Text(playlistName)
                    .font(.system(size: 15, design: .rounded))
                    .opacity(0.85)
                    .padding(.top, 4)

                progressBar(progress: progress)
                    .padding(.top, 18)

                HStack {
                    Text(formatTime(audioPlayer.currentTime))
                    Spacer()
                    Text("-\(formatTime(remaining))")
                }
                .font(.system(size: 12, design: .rounded))
                .opacity(0.8)
                .padding(.top, 6)

                transportRow(accentA: visual.accentA)
                    .padding(.top, 18)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: visual.accentB, location: 0),
                        .init(color: visual.accentA, location: 0.7),
                        .init(color: .black, location: 1.3),
                    ],
                    startPoint: UnitPoint(x: 0, y: 0),
                    endPoint: UnitPoint(x: 1, y: 1)
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
            .shadow(color: visual.accentA.opacity(0.33), radius: 18, x: 0, y: 16)
        }
        .buttonStyle(.plain)
    }

    private func nowPlayingResume(record: StoryRecord) -> some View {
        let folder = folders.first { $0.dropboxPath == record.parentFolderPath }
        let name = folder?.displayName ?? (record.parentFolderPath as NSString).lastPathComponent
        let visual = PlaylistVisual.make(from: name)
        return Button {
            // Try to find this story in the loaded files list and play it.
            if let folder, let file = dropboxService.files(in: folder.dropboxPath).first(where: { $0.id == record.dropboxFileId }) {
                playStory(file: file, in: folder)
            } else {
                openPlayer = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("CONTINUE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2)
                    .opacity(0.85)

                Text(record.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.5)
                    .lineLimit(2)
                    .padding(.top, 16)

                Text(name)
                    .font(.system(size: 15, design: .rounded))
                    .opacity(0.85)
                    .padding(.top, 4)

                if record.duration > 0 {
                    progressBar(progress: record.listenedFraction)
                        .padding(.top, 18)
                    HStack {
                        Text(formatTime(record.lastPosition))
                        Spacer()
                        Text("-\(formatTime(max(record.duration - record.lastPosition, 0)))")
                    }
                    .font(.system(size: 12, design: .rounded))
                    .opacity(0.8)
                    .padding(.top, 6)
                }

                HStack {
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(visual.accentA)
                        .frame(width: 64, height: 64)
                        .background(Color.white)
                        .clipShape(Circle())
                    Spacer()
                }
                .padding(.top, 18)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
            .background(
                LinearGradient(
                    colors: [visual.accentB, visual.accentA],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
            .shadow(color: visual.accentA.opacity(0.33), radius: 18, x: 0, y: 16)
        }
        .buttonStyle(.plain)
    }

    private var ccPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "captions.bubble")
                .font(.system(size: 12, weight: .medium))
            Text("off")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.25)).frame(height: 4)
                Capsule().fill(Color.white).frame(width: proxy.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }

    private func transportRow(accentA: Color) -> some View {
        HStack {
            Button { audioPlayer.skipBackward() } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.16))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button { audioPlayer.togglePlayPause() } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(accentA)
                    .frame(width: 78, height: 78)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { audioPlayer.skipForward() } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.16))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Favorites

    @ViewBuilder
    private var favoritesSection: some View {
        if !favorites.isEmpty {
            sectionTitle("Favorites", action: nil) { }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 10)
            VStack(spacing: 8) {
                ForEach(Array(favorites.prefix(3))) { record in
                    favoriteRow(record: record)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func favoriteRow(record: StoryRecord) -> some View {
        let folder = folders.first { $0.dropboxPath == record.parentFolderPath }
        let name = folder?.displayName ?? (record.parentFolderPath as NSString).lastPathComponent
        let visual = PlaylistVisual.make(from: name)
        return Button {
            if let folder, let file = dropboxService.files(in: folder.dropboxPath).first(where: { $0.id == record.dropboxFileId }) {
                playStory(file: file, in: folder)
            }
        } label: {
            HStack(spacing: 12) {
                StoryCover(playlist: visual, storyTitle: record.title, cornerRadius: 10)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Color.ink)
                        .lineLimit(1)
                    Text(name)
                        .font(.system(size: 12.5, design: .rounded))
                        .foregroundColor(Theme.Color.inkFaint)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Color.accent)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 64)
            .background(Theme.Color.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(Theme.Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - All playlists

    private var allPlaylistsSection: some View {
        VStack(spacing: 0) {
            sectionTitle("All playlists", action: "See all →") { openAllPlaylists = true }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 10)

            if playlistsLayout == "grid" {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                    spacing: 14
                ) {
                    ForEach(folders.prefix(6)) { folder in
                        Button { openPlaylist = folder } label: {
                            playlistTile(folder: folder, big: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 0) {
                    let visible = Array(folders.prefix(6))
                    ForEach(Array(visible.enumerated()), id: \.element.dropboxPath) { idx, folder in
                        Button { openPlaylist = folder } label: {
                            playlistListRow(folder: folder)
                        }
                        .buttonStyle(.plain)
                        if idx < visible.count - 1 {
                            Divider().background(Theme.Color.border)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func playlistTile(folder: StoryFolder, big: Bool) -> some View {
        let count = dropboxService.files(in: folder.dropboxPath).count
        let visual = PlaylistVisual.make(from: folder.displayName)
        return VStack(alignment: .leading, spacing: 0) {
            PlaylistCover(visual: visual, cornerRadius: 12)
                .aspectRatio(1, contentMode: .fit)
            Text(folder.displayName)
                .font(.system(size: big ? 16 : 14.5, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.Color.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.top, 10)
            Text(count > 0 ? "\(count) stories" : "tap to load")
                .font(.system(size: 12.5, design: .rounded))
                .foregroundColor(Theme.Color.inkFaint)
                .padding(.top, 3)
        }
        .padding(big ? 12 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private func playlistListRow(folder: StoryFolder) -> some View {
        let count = dropboxService.files(in: folder.dropboxPath).count
        let visual = PlaylistVisual.make(from: folder.displayName)
        return HStack(spacing: 14) {
            PlaylistCover(visual: visual, cornerRadius: 12)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.displayName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Color.ink)
                    .lineLimit(1)
                Text(count > 0 ? "\(count) stories" : "tap to load")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Theme.Color.inkFaint)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Color.inkFaint)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Recently played

    @ViewBuilder
    private var recentlyPlayedSection: some View {
        let items = Array(recents.prefix(4))
        if !items.isEmpty {
            sectionTitle("Recently played", action: nil) { }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 10)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, record in
                    recentRow(record: record)
                    if idx < items.count - 1 {
                        Divider().background(Theme.Color.border)
                    }
                }
            }
            .padding(.horizontal, 22)
        }
    }

    private func recentRow(record: StoryRecord) -> some View {
        let folder = folders.first { $0.dropboxPath == record.parentFolderPath }
        let name = folder?.displayName ?? (record.parentFolderPath as NSString).lastPathComponent
        let visual = PlaylistVisual.make(from: name)
        return Button {
            if let folder, let file = dropboxService.files(in: folder.dropboxPath).first(where: { $0.id == record.dropboxFileId }) {
                playStory(file: file, in: folder)
            }
        } label: {
            HStack(spacing: 12) {
                StoryCover(playlist: visual, storyTitle: record.title, cornerRadius: 9)
                    .frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Color.ink)
                        .lineLimit(1)
                    Text(name)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Theme.Color.inkFaint)
                }
                Spacer()
                if record.duration > 0 {
                    Text(formatTime(record.duration))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Theme.Color.inkFaint)
                }
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Color.accent)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            // Subtle warm wash so the welcome screen doesn't read as a blank slate
            Spacer()

            brandMark
                .padding(.bottom, 28)

            VStack(spacing: 12) {
                Text("StoryRide")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .tracking(-0.5)
                    .foregroundColor(Theme.Color.ink)

                Text("Audio stories from your Dropbox, with read-along captions on screen. Built for kids in the car.")
                    .font(.system(size: 15.5, design: .rounded))
                    .foregroundColor(Theme.Color.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }

            Spacer()

            VStack(spacing: 10) {
                Text("PICK A WAY TO ADD AUDIO")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundColor(Theme.Color.inkFaint)

                HStack(spacing: 12) {
                    Button { showDiscover = true } label: {
                        ctaTile(
                            icon: "sparkle.magnifyingglass",
                            label: "Scan Dropbox",
                            sub: "find audio folders",
                            primary: true
                        )
                    }
                    .buttonStyle(.plain)

                    Button { showAddFolder = true } label: {
                        ctaTile(
                            icon: "folder.badge.plus",
                            label: "Add a folder",
                            sub: "browse manually",
                            primary: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // Soft honey wash at the top so the screen feels intentional, not empty
            LinearGradient(
                stops: [
                    .init(color: Theme.Color.accent.opacity(0.10), location: 0),
                    .init(color: Theme.Color.bg, location: 0.45),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var brandMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.Color.accent)
                .frame(width: 96, height: 96)
                .shadow(color: Theme.Color.accent.opacity(0.40), radius: 24, x: 0, y: 14)

            // Play triangle, optically nudged right of center
            Image(systemName: "play.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(Theme.Color.bg)
                .offset(x: 3)
        }
    }

    /// One of two equally-weighted CTA tiles on the welcome screen.
    /// Same size, shape, structure. Primary uses an accent border (so the brand mark
    /// stays the only solid block of honey); secondary uses a card surface.
    private func ctaTile(icon: String, label: String, sub: String, primary: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            Text(sub)
                .font(.system(size: 11.5, design: .rounded))
                .opacity(0.75)
        }
        .foregroundColor(primary ? Theme.Color.accent : Theme.Color.ink)
        .frame(maxWidth: .infinity)
        .frame(height: 116)
        .background(primary ? Theme.Color.accent.opacity(0.08) : Theme.Color.card)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    primary ? Theme.Color.accent.opacity(0.65) : Theme.Color.border,
                    lineWidth: primary ? 1.5 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String, action: String?, onAction: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .tracking(-0.2)
                .foregroundColor(Theme.Color.ink)
            Spacer()
            if let action {
                Button(action: onAction) {
                    Text(action)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Color.accent)
                }
            }
        }
    }

    private func playlistName(for path: String?) -> String {
        guard let path else { return "" }
        if let folder = folders.first(where: { $0.dropboxPath == path }) {
            return folder.displayName
        }
        return (path as NSString).lastPathComponent
    }

    private func continueRecord() -> StoryRecord? {
        if !lastPlayedStoryId.isEmpty,
           let match = recents.first(where: { $0.dropboxFileId == lastPlayedStoryId }) {
            return match
        }
        return recents.first
    }

    private func playStory(file: DropboxFile, in folder: StoryFolder) {
        audioPlayer.attach(file: file, playlistPath: folder.dropboxPath)
        lastPlayedStoryId = file.id
        openPlayer = true
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }
}
