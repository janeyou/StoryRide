import Foundation
import AVFoundation
import MediaPlayer
import Combine

class AudioPlayerService: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentTitle: String = ""
    @Published var currentFile: DropboxFile?
    @Published var currentPlaylistPath: String?
    /// The file currently loaded into the underlying AVAudioPlayer. May lag `currentFile`
    /// when a new file has been attached but its bytes haven't been loaded yet.
    @Published var loadedFileId: String?

    /// Queue of files to play after the current one finishes (for "Play all" / "Shuffle").
    @Published private(set) var queue: [DropboxFile] = []
    @Published private(set) var queueIndex: Int = 0

    /// True when a file has been loaded — used by MiniPlayer visibility.
    var hasLoadedTrack: Bool { currentFile != nil }

    /// Optional hook called when the current track advances or finishes. Lets the UI
    /// trigger a new download/transcribe pass for the new file.
    var onTrackAdvance: ((DropboxFile, String?) -> Void)?

    private var player: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    private var cancellables = Set<AnyCancellable>()
    private lazy var playerDelegate: PlayerDelegate = {
        PlayerDelegate(onFinish: { [weak self] in self?.handleTrackFinish() })
    }()

    private func handleTrackFinish() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isPlaying = false
            self.stopDisplayLink()
            if self.advanceToNext() == nil {
                self.currentTime = self.duration
                self.updateNowPlaying()
            }
            // The caller's onTrackAdvance hook handles loading the new file and calling play().
        }
    }

    init() {
        configureAudioSession()
        setupRemoteControls()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func load(url: URL, title: String, fileId: String) throws {
        player = try AVAudioPlayer(contentsOf: url)
        player?.delegate = playerDelegate
        player?.prepareToPlay()
        duration = player?.duration ?? 0
        currentTime = 0
        currentTitle = title
        loadedFileId = fileId
        updateNowPlaying()
    }

    /// Attach the file/playlist metadata to the currently-loaded player. Call after `load`.
    func attach(file: DropboxFile, playlistPath: String?) {
        currentFile = file
        currentPlaylistPath = playlistPath
    }

    /// Replace the queue and play from the given index.
    func setQueue(_ files: [DropboxFile], playlistPath: String?, startIndex: Int = 0) {
        queue = files
        queueIndex = max(0, min(startIndex, files.count - 1))
        currentPlaylistPath = playlistPath
        if let file = queue[safe: queueIndex] {
            onTrackAdvance?(file, playlistPath)
        }
    }

    /// Advance to the next file in the queue, if any. Returns the file or nil.
    @discardableResult
    func advanceToNext() -> DropboxFile? {
        guard queueIndex + 1 < queue.count else { return nil }
        queueIndex += 1
        let next = queue[queueIndex]
        onTrackAdvance?(next, currentPlaylistPath)
        return next
    }

    func play() {
        player?.play()
        isPlaying = true
        startDisplayLink()
        updateNowPlaying()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopDisplayLink()
        updateNowPlaying()
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func skipForward(_ seconds: TimeInterval = 15) {
        guard let player = player else { return }
        let newTime = min(player.currentTime + seconds, player.duration)
        player.currentTime = newTime
        currentTime = newTime
    }

    func skipBackward(_ seconds: TimeInterval = 15) {
        guard let player = player else { return }
        let newTime = max(player.currentTime - seconds, 0)
        player.currentTime = newTime
        currentTime = newTime
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateTime))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateTime() {
        guard let player = player else { return }
        currentTime = player.currentTime

        if !player.isPlaying && currentTime >= duration - 0.1 {
            isPlaying = false
            stopDisplayLink()
        }
    }

    private func setupRemoteControls() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }
    }

    private func updateNowPlaying() {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = currentTitle
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        onFinish()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
