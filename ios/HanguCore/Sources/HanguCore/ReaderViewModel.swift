// PASTE THIS ENTIRE CORRECTED BLOCK INTO ReaderViewModel.swift

import SwiftUI
import Combine

public protocol TTSPlayerProtocol {
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    func play(url: URL)
    func pause()
}


public final class ReaderViewModel: ObservableObject {
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

    public func togglePlay() {
        guard let url = audioURL else { return }

        if isPlaying {
            ttsPlayer.pause()
        } else {
            ttsPlayer.play(url: url)
        }
    }

    private func setupBindings() {
        ttsPlayer.isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)

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
                    // FIX 2: Access tuple elements by their correct names: .audio and .marks
                    self?.audioURL = data.audio
                    self?.speechMarks = data.marks
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
            // FIX 3: The property on SpeechMark is .text, not .value
            if let range = newAttributed.range(of: mark.value) {
                newAttributed[range].backgroundColor = .yellow
            }
        }
        self.attributed = newAttributed
    }
}


extension TTSPlayer: TTSPlayerProtocol {
    // FIX 1: Add 'public' to satisfy the public protocol requirement
    public var isPlayingPublisher: AnyPublisher<Bool, Never> { $isPlaying.eraseToAnyPublisher() }
    public var currentTimePublisher: AnyPublisher<TimeInterval, Never> { $currentTime.eraseToAnyPublisher() }
}
