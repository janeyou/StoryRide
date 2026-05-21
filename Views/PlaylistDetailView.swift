import SwiftUI
import SwiftData

struct PlaylistDetailView: View {
    let folder: StoryFolder
    @EnvironmentObject var dropboxService: DropboxService
    @EnvironmentObject var audioPlayer: AudioPlayerService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var stories: [StoryRecord]
    @State private var openPlayer = false
    @State private var loadError: String?

    private var visual: PlaylistVisual { PlaylistVisual.make(from: folder.displayName) }
    private var files: [DropboxFile] { dropboxService.files(in: folder.dropboxPath) }
    private var totalDuration: TimeInterval {
        // Sum of locally-known durations from StoryRecord, if any. Fallback: 0.
        files.reduce(0) { sum, file in
            sum + (storyFor(fileId: file.id)?.duration ?? 0)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Color.bg.ignoresSafeArea()

            // Gradient header backdrop
            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: visual.accentA.opacity(0.80), location: 0),
                        .init(color: visual.accentA.opacity(0.33), location: 0.30),
                        .init(color: Theme.Color.bg, location: 0.78),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 420)
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    DialTopBar(
                        eyebrow: "PLAYLIST",
                        title: "",
                        eyebrowColor: .white.opacity(0.85),
                        onBack: { dismiss() }
                    ) {
                        DialIconButton(
                            systemName: "ellipsis",
                            action: {},
                            foreground: Theme.Color.ink,
                            background: Color.white.opacity(0.10)
                        )
                    }

                    coverHeader
                        .padding(.horizontal, 22)
                        .padding(.top, 8)

                    actionRow
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                    storyList
                        .padding(.horizontal, 16)
                        .padding(.top, 22)
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
        .task { await ensureFilesLoaded() }
        .navigationDestination(isPresented: $openPlayer) { PlayerView() }
        .alert("Error", isPresented: .constant(loadError != nil)) {
            Button("OK") { loadError = nil }
        } message: {
            Text(loadError ?? "")
        }
    }

    // MARK: - Header

    private var coverHeader: some View {
        VStack(spacing: 0) {
            PlaylistCover(visual: visual, cornerRadius: Theme.Radius.detailCover)
                .frame(width: 168, height: 168)
                .shadow(color: .black.opacity(0.30), radius: 24, x: 0, y: 12)

            Text(folder.displayName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .foregroundColor(Theme.Color.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 18)

            Text(metaText)
                .font(.system(size: 13.5, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var metaText: String {
        let count = files.count
        if totalDuration > 0 {
            let min = Int(round(totalDuration / 60))
            return "\(count) stories · \(min) min total"
        }
        return "\(count) stories"
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                playAll(shuffle: false)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Play all")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(Theme.Color.accentFg)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.Color.accent)
                .clipShape(Capsule())
                .shadow(color: Theme.Color.accent.opacity(0.33), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(files.isEmpty)

            Button { playAll(shuffle: true) } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Color.ink)
                    .frame(width: 56, height: 56)
                    .background(Theme.Color.card)
                    .overlay(Circle().stroke(Theme.Color.border, lineWidth: 1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(files.isEmpty)

            Button { toggleStarFavoriteForFolder() } label: {
                Image(systemName: "star.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Color.accent)
                    .frame(width: 56, height: 56)
                    .background(Theme.Color.card)
                    .overlay(Circle().stroke(Theme.Color.border, lineWidth: 1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Story list

    private var storyList: some View {
        VStack(spacing: 6) {
            if files.isEmpty {
                emptyState
            } else {
                ForEach(Array(files.enumerated()), id: \.element.id) { idx, file in
                    storyRow(index: idx, file: file)
                }
            }
        }
    }

    private func storyRow(index: Int, file: DropboxFile) -> some View {
        let record = storyFor(fileId: file.id)
        let listened = record?.listenedFraction ?? 0
        let done = listened >= 1
        let inProgress = listened > 0 && listened < 1
        let starred = record?.isStarred ?? false

        return Button { play(file: file) } label: {
            HStack(spacing: 14) {
                ZStack {
                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.Color.accent)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.Color.inkSoft)
                    }
                }
                .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(file.displayTitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(done ? Theme.Color.inkFaint : Theme.Color.ink)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if let record, record.duration > 0 {
                            Text(formatTime(record.duration))
                                .font(.system(size: 12.5, design: .rounded))
                                .foregroundColor(Theme.Color.inkFaint)
                        }
                        if inProgress {
                            Text("·").foregroundColor(Theme.Color.inkFaint.opacity(0.5))
                            Text("\(Int(listened * 100))% in")
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.Color.accent)
                        }
                        if starred {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Color.accent)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(inProgress ? Theme.Color.accentFg : Theme.Color.accent)
                    .frame(width: 44, height: 44)
                    .background(inProgress ? Theme.Color.accent : Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .padding(.leading, 14)
            .padding(.trailing, 10)
            .padding(.vertical, 12)
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

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("Loading…")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Theme.Color.inkFaint)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    // MARK: - Actions

    private func play(file: DropboxFile) {
        audioPlayer.attach(file: file, playlistPath: folder.dropboxPath)
        UserDefaults.standard.set(file.id, forKey: "lastPlayedStoryId")
        openPlayer = true
    }

    private func playAll(shuffle: Bool) {
        guard !files.isEmpty else { return }
        let queue = shuffle ? files.shuffled() : files
        audioPlayer.setQueue(queue, playlistPath: folder.dropboxPath, startIndex: 0)
        if let first = queue.first {
            audioPlayer.attach(file: first, playlistPath: folder.dropboxPath)
            UserDefaults.standard.set(first.id, forKey: "lastPlayedStoryId")
        }
        openPlayer = true
    }

    private func toggleStarFavoriteForFolder() {
        // For now this is a no-op placeholder for the folder-level star button.
        // Per-story starring lives on the row. A future change can persist a
        // "starred folder" preference.
    }

    private func ensureFilesLoaded() async {
        if !files.isEmpty { return }
        do {
            try await dropboxService.listAudioFiles(in: folder.dropboxPath)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func storyFor(fileId: String) -> StoryRecord? {
        stories.first { $0.dropboxFileId == fileId }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }
}
