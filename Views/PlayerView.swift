import SwiftUI
import SwiftData

struct PlayerView: View {
    let file: DropboxFile
    @EnvironmentObject var dropboxService: DropboxService
    @Environment(\.modelContext) private var modelContext
    @StateObject private var audioPlayer = AudioPlayerService()
    @StateObject private var captionEngine = CaptionSyncEngine()
    @State private var isLoadingAudio = false
    @State private var isTranscribing = false
    @State private var errorMessage: String?

    private let riviera = RivieraAPIClient()

    var body: some View {
        ZStack {
            Theme.Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                captionArea
                    .frame(maxHeight: .infinity)

                controlsArea
                    .frame(height: 220)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(file.displayTitle)
                    .font(Theme.Font.body(16, weight: .regular))
                    .foregroundColor(Theme.Color.textStrong)
                    .lineLimit(1)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { loadAndPlay() }
        .onDisappear { audioPlayer.pause() }
        .onChange(of: audioPlayer.currentTime) { _, newTime in
            captionEngine.update(currentTime: newTime)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var captionArea: some View {
        VStack {
            if isTranscribing {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(Theme.Color.text)
                        .scaleEffect(1.4)
                    Text("Transcribing")
                        .font(Theme.Font.body(17))
                        .foregroundColor(Theme.Color.textMuted)
                }
            } else if captionEngine.visibleWords.isEmpty {
                Text(isLoadingAudio ? "Loading" : "")
                    .font(Theme.Font.display(36, weight: .regular))
                    .foregroundColor(Theme.Color.textFaint)
            } else {
                CaptionView(words: captionEngine.visibleWords)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    private var controlsArea: some View {
        ControlsView(
            isPlaying: audioPlayer.isPlaying,
            currentTime: audioPlayer.currentTime,
            duration: audioPlayer.duration,
            onPlayPause: { audioPlayer.togglePlayPause() },
            onSkipBack: { audioPlayer.skipBackward() },
            onSkipForward: { audioPlayer.skipForward() }
        )
    }

    private func loadAndPlay() {
        Task {
            do {
                isLoadingAudio = true
                let localURL = FileCache.localURL(for: file.name)

                if !FileManager.default.fileExists(atPath: localURL.path) {
                    try await dropboxService.downloadFile(path: file.path, to: localURL)
                }

                try audioPlayer.load(url: localURL, title: file.displayTitle)
                audioPlayer.play()
                isLoadingAudio = false

                await transcribeIfNeeded()
            } catch {
                isLoadingAudio = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func transcribeIfNeeded() async {
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
            upsertStoryRecord()
        } catch {
            errorMessage = "Transcription: \(error.localizedDescription)"
        }
        isTranscribing = false
    }

    private func upsertStoryRecord() {
        let fileId = file.id
        let existing = (try? modelContext.fetch(FetchDescriptor<StoryRecord>(
            predicate: #Predicate { $0.dropboxFileId == fileId }
        )))?.first

        if let existing {
            existing.contentHash = file.contentHash
            existing.lastPlayedAt = Date()
        } else {
            let record = StoryRecord(
                dropboxFileId: file.id,
                title: file.displayTitle,
                dropboxPath: file.path,
                contentHash: file.contentHash,
                duration: audioPlayer.duration
            )
            record.lastPlayedAt = Date()
            modelContext.insert(record)
        }
        try? modelContext.save()
    }
}
