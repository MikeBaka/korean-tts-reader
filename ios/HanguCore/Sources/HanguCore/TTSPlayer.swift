import Foundation
import AVFoundation
import Combine

public final class TTSPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published public var currentTime: TimeInterval = 0
    @Published public private(set) var isPlaying: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var displayLink: CADisplayLink?

    public override init() {
        super.init()
    }

    public func play(url: URL) {
        // Stop any existing playback
        reset()

        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            // Initialize and play the audio
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true

            // Set up the display link to publish time updates
            let link = CADisplayLink(target: self, selector: #selector(updateCurrentTime))
            link.preferredFramesPerSecond = 20 // ~50ms interval
            link.add(to: .main, forMode: .common)
            displayLink = link

        } catch {
            print("TTSPlayer Error: Failed to initialize or play audio. \(error.localizedDescription)")
            reset() // Clean up on failure
        }
    }

    public func pause() {
        guard let player = audioPlayer, player.isPlaying else { return }
        player.pause()
        displayLink?.isPaused = true
        isPlaying = false
    }
    
    public func resume() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        player.play()
        displayLink?.isPaused = false
        isPlaying = true
    }

    private func reset() {
        audioPlayer?.stop()
        audioPlayer = nil
        displayLink?.invalidate()
        displayLink = nil
        currentTime = 0
        isPlaying = false
    }

    @objc private func updateCurrentTime() {
        // Directly update the published property from the main run loop
        self.currentTime = audioPlayer?.currentTime ?? 0
    }

    // MARK: - AVAudioPlayerDelegate

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        reset()
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("TTSPlayer Error: Audio decode error. \(error.localizedDescription)")
        }
        reset()
    }
}