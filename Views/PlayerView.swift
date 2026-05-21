import SwiftUI
import SwiftData

/// Full-screen playback. Captions hidden by default; tap the CC pill to reveal.
/// Pulls the active file from `AudioPlayerService.currentFile` (set by the caller
/// via `audioPlayer.attach(...)` before navigating here).
struct PlayerView: View {
    @EnvironmentObject var dropboxService: DropboxService
    @EnvironmentObject var audioPlayer: AudioPlayerService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var captionEngine = CaptionSyncEngine()
    @Query private var stories: [StoryRecord]
    @AppStorage("captionFontSize") private var captionFontSize: Double = 36
    @AppStorage("captionsDefaultOn") private var captionsDefaultOn: Bool = false
    @State private var captionsOpen = false
    @State private var isLoadingAudio = false
    @State private var isTranscribing = false
    @State private var errorMessage: String?

    private let riviera = RivieraAPIClient()

    var body: some View {
        ZStack {
            Theme.Color.bg.ignoresSafeArea()

            if let file = audioPlayer.currentFile {
                content(file: file)
            } else {
                noTrackState
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            captionsOpen = captionsDefaultOn
            handleFileChange()
        }
        .onChange(of: audioPlayer.currentFile?.id) { _, _ in handleFileChange() }
        .onChange(of: audioPlayer.currentTime) { _, newTime in
            captionEngine.update(currentTime: newTime)
        }
        .onDisappear { persistLastPosition() }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Layout

    private func content(file: DropboxFile) -> some View {
        let visual = PlaylistVisual.make(from: playlistName)

        return ZStack {
            // Gradient wash
            VStack {
                LinearGradient(
                    stops: [
                        .init(color: visual.accentA.opacity(0.80), location: 0),
                        .init(color: visual.accentA.opacity(0.33), location: 0.30),
                        .init(color: .clear, location: 0.60),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 480)
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 0) {
                    topChrome
                        .padding(.horizontal, 16)
                        .padding(.top, 54)

                    surface(visual: visual)
                        .padding(.horizontal, 28)
                        .padding(.top, 24)

                    titleBlock(file: file)
                        .padding(.horizontal, 28)
                        .padding(.top, 22)

                    progressBlock
                        .padding(.horizontal, 28)
                        .padding(.top, 24)

                    transportRow(accentA: visual.accentA)
                        .padding(.horizontal, 28)
                        .padding(.top, 20)

                    captionPill
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }
        }
    }

    private var noTrackState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(Theme.Color.inkFaint)
            Text("Nothing playing")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.Color.inkSoft)
            Button("Close") { dismiss() }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.Color.accent)
        }
    }

    private var topChrome: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Color.ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("PLAYING FROM")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundColor(Theme.Color.ink.opacity(0.7))
                Text(playlistName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Color.ink)
                    .lineLimit(1)
            }

            Spacer()

            Button { /* more */ } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Color.ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    .clipShape(Circle())
            }
        }
    }

    @ViewBuilder
    private func surface(visual: PlaylistVisual) -> some View {
        ZStack {
            if captionsOpen {
                captionPanel
                    .transition(.opacity)
            } else {
                coverSurface(visual: visual)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: captionsOpen)
        .frame(maxWidth: 320)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private func coverSurface(visual: PlaylistVisual) -> some View {
        ZStack(alignment: .topTrailing) {
            PlaylistCover(visual: visual, cornerRadius: Theme.Radius.playerCover)
            Button { toggleStar() } label: {
                Image(systemName: currentStoryIsStarred ? "star.fill" : "star")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Color.accent)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial.opacity(0.55))
                    .environment(\.colorScheme, .dark)
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    .clipShape(Circle())
            }
            .padding(14)
        }
    }

    private var captionPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.playerCover, style: .continuous)
                .fill(Color.black.opacity(0.45))
            RoundedRectangle(cornerRadius: Theme.Radius.playerCover, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            RoundedRectangle(cornerRadius: Theme.Radius.playerCover, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)

            captionContent
                .padding(24)
        }
    }

    private var captionContent: some View {
        Group {
            if isTranscribing {
                VStack(spacing: 12) {
                    ProgressView().tint(Theme.Color.ink).scaleEffect(1.2)
                    Text("Transcribing")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(Theme.Color.inkSoft)
                }
            } else if captionEngine.visibleWords.isEmpty {
                Text(isLoadingAudio ? "Loading…" : "No caption yet")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Theme.Color.inkFaint)
            } else {
                CaptionView(words: captionEngine.visibleWords)
            }
        }
    }

    private func titleBlock(file: DropboxFile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(file.displayTitle)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .foregroundColor(Theme.Color.ink)
                .lineLimit(2)
            Text(metaText)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Theme.Color.ink.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaText: String {
        let min = Int(round(audioPlayer.duration / 60))
        return min > 0 ? "narrated · \(min) min" : "narrated"
    }

    private var progressBlock: some View {
        VStack(spacing: 7) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15)).frame(height: 4)
                    Capsule()
                        .fill(Theme.Color.accent)
                        .frame(width: proxy.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                Text(formatTime(audioPlayer.currentTime))
                Spacer()
                Text("-\(formatTime(max(audioPlayer.duration - audioPlayer.currentTime, 0)))")
            }
            .font(.system(size: 12, design: .rounded))
            .foregroundColor(Theme.Color.ink.opacity(0.7))
        }
    }

    private func transportRow(accentA: Color) -> some View {
        HStack {
            Button { audioPlayer.skipBackward() } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Theme.Color.ink)
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button { audioPlayer.togglePlayPause() } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.Color.accentFg)
                    .frame(width: 80, height: 80)
                    .background(Theme.Color.accent)
                    .clipShape(Circle())
                    .shadow(color: Theme.Color.accent.opacity(0.33), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { audioPlayer.skipForward() } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Theme.Color.ink)
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var captionPill: some View {
        Button { captionsOpen.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: "captions.bubble")
                    .font(.system(size: 16, weight: .medium))
                Text(captionsOpen ? "Hide read-along" : "Show read-along")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(captionsOpen ? Theme.Color.accentFg : Theme.Color.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(captionsOpen ? Theme.Color.accent : Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private var playlistName: String {
        guard let path = audioPlayer.currentPlaylistPath else { return "" }
        let last = (path as NSString).lastPathComponent
        return last.isEmpty ? "/" : last
    }

    private var progress: Double {
        audioPlayer.duration > 0 ? audioPlayer.currentTime / audioPlayer.duration : 0
    }

    private var currentStoryIsStarred: Bool {
        guard let fileId = audioPlayer.currentFile?.id else { return false }
        return stories.first { $0.dropboxFileId == fileId }?.isStarred ?? false
    }

    private func toggleStar() {
        guard let file = audioPlayer.currentFile else { return }
        upsertStoryRecord(file: file) { record in
            record.isStarred.toggle()
        }
    }

    private func handleFileChange() {
        guard let file = audioPlayer.currentFile else { return }
        if audioPlayer.loadedFileId == file.id { return }  // already loaded by a previous open
        loadAndPlay(file: file)
    }

    private func loadAndPlay(file: DropboxFile) {
        Task {
            do {
                isLoadingAudio = true
                let localURL = FileCache.localURL(for: file.name)
                if !FileManager.default.fileExists(atPath: localURL.path) {
                    try await dropboxService.downloadFile(path: file.path, to: localURL)
                }

                try audioPlayer.load(url: localURL, title: file.displayTitle, fileId: file.id)
                if let record = storyFor(fileId: file.id), record.lastPosition > 0, record.lastPosition < audioPlayer.duration - 5 {
                    audioPlayer.seek(to: record.lastPosition)
                }
                audioPlayer.play()
                isLoadingAudio = false

                upsertStoryRecord(file: file) { record in
                    record.lastPlayedAt = Date()
                    if record.duration == 0 { record.duration = audioPlayer.duration }
                }

                await transcribeIfNeeded(file: file)
            } catch {
                isLoadingAudio = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func transcribeIfNeeded(file: DropboxFile) async {
        if let cached = TranscriptStore.load(hash: file.contentHash) {
            captionEngine.load(segments: cached)
            return
        }
        guard let token = await dropboxService.getAccessToken() else { return }
        isTranscribing = true
        do {
            let segments = try await riviera.transcribe(filePath: file.path, token: token)
            captionEngine.load(segments: segments)
            try TranscriptStore.save(segments, hash: file.contentHash)
        } catch {
            errorMessage = "Transcription: \(error.localizedDescription)"
        }
        isTranscribing = false
    }

    private func persistLastPosition() {
        guard let file = audioPlayer.currentFile else { return }
        upsertStoryRecord(file: file) { record in
            record.lastPosition = audioPlayer.currentTime
            record.lastPlayedAt = Date()
        }
    }

    private func storyFor(fileId: String) -> StoryRecord? {
        stories.first { $0.dropboxFileId == fileId }
    }

    private func upsertStoryRecord(file: DropboxFile, mutate: (StoryRecord) -> Void) {
        let fileId = file.id
        let existing = (try? modelContext.fetch(FetchDescriptor<StoryRecord>(
            predicate: #Predicate { $0.dropboxFileId == fileId }
        )))?.first

        let record: StoryRecord
        if let existing {
            existing.contentHash = file.contentHash
            existing.title = file.displayTitle
            existing.dropboxPath = file.path
            record = existing
        } else {
            record = StoryRecord(
                dropboxFileId: file.id,
                title: file.displayTitle,
                dropboxPath: file.path,
                contentHash: file.contentHash,
                duration: audioPlayer.duration
            )
            modelContext.insert(record)
        }
        mutate(record)
        do {
            try modelContext.save()
        } catch {
            print("[PlayerView] save failed: \(error)")
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }
}
