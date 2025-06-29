// PASTE THIS ENTIRE BLOCK INTO ReaderViewModel.swift

import SwiftUI
import Combine

// This protocol should probably be in its own file, but here is fine for now.
public protocol TTSPlayerProtocol {
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    func play(url: URL)
    func pause()
}


public final class ReaderViewModel: ObservableObject {
    // FIX 1: Single, consolidated property declarations
    @Published public private(set) var isPlaying: Bool = false
    @Published public var attributed: AttributedString
    @Published public var speechMarks: [SpeechMark] = []
    @Published public var currentWordIndex: Int = -1

    private let originalText: String
    private var audioURL: URL?
    private let pollyManager = PollyManager()
    private let ttsPlayer: TTSPlayerProtocol
    private var cancellables = Set<AnyCancellable>()

    public init(text: String, ttsPlayer: TTSPlayerProtocol = TTSPlayer()) {
        self.originalText = text
        self.ttsPlayer = ttsPlayer
        self.attributed = AttributedString(text)
        setupBindings()
        synthesizeText()
    }

    // FIX 2: Single, correct togglePlay() function
    public func togglePlay() {
        guard let url = audioURL else { return }

        if isPlaying {
            ttsPlayer.pause()
        } else {
            ttsPlayer.play(url: url) // FIX 3: Pass the required 'url' parameter
        }
    }

    private func setupBindings() {
        // Bind the player's isPlaying state to our published property
        ttsPlayer.isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)

        // Listen for time updates to highlight words
        ttsPlayer.currentTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.updateHighlight(at: time)
            }
            .store(in: &cancellables)
    }

    private func synthesizeText() {
        pollyManager.synthesize(text: originalText) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.audioURL = data.audioURL
                    self?.speechMarks = data.speechMarks
                    // Now that we have speech marks, you might want to update the attributed string
                    self?.updateAttributedString()
                case .failure(let error):
                    print("Synthesis failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateHighlight(at time: TimeInterval) {
        let timeInMs = Int(time * 1000)
        guard let newIndex = speechMarks.lastIndex(where: { $0.startMs <= timeInMs }) else {
            return
        }

        if currentWordIndex != newIndex {
            currentWordIndex = newIndex
            updateAttributedString()
        }
    }

    private func updateAttributedString() {
        var newAttributed = AttributedString(originalText)
        if currentWordIndex >= 0 && currentWordIndex < speechMarks.count {
            let mark = speechMarks[currentWordIndex]
            if let range = newAttributed.range(of: mark.value) {
                newAttributed[range].backgroundColor = .yellow
            }
        }
        self.attributed = newAttributed
    }

// FIX 4: The class's closing brace was moved here, to the very end of the class.
}


// The extension must be OUTSIDE the class definition.
extension TTSPlayer: TTSPlayerProtocol {
    // These computed properties make TTSPlayer conform to the protocol
    var isPlayingPublisher: AnyPublisher<Bool, Never> { $isPlaying.eraseToAnyPublisher() }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { $currentTime.eraseToAnyPublisher() }
}
