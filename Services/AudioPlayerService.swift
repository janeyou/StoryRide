import Foundation
import AVFoundation
import MediaPlayer
import Combine

class AudioPlayerService: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentTitle: String = ""

    private var player: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    private var cancellables = Set<AnyCancellable>()

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

    func load(url: URL, title: String) throws {
        player = try AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        duration = player?.duration ?? 0
        currentTime = 0
        currentTitle = title
        updateNowPlaying()
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
