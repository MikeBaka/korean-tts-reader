// PASTE THIS FINAL VERSION INTO ReaderViewModel.swift

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

    // THE FIX: The init method takes no arguments again.
    public init() {
        let sampleText = """
        안녕하세요, 만나서 반갑습니다. 제 이름은 루입니다.
        이것은 스크롤 테스트를 위한 긴 텍스트입니다.
        자동 스크롤 기능이 하이라이트된 단어를 화면의 상단 1/3 지점에 유지하는지 확인해 보겠습니다.
        뷰가 업데이트될 때 스크롤이 부드럽게 이동해야 합니다.
        이 기능은 사용자가 텍스트를 편안하게 따라 읽을 수 있도록 도와줍니다.
        마지막 줄까지 테스트해 보겠습니다.
        """
        self.originalText = sampleText
        self.ttsPlayer = TTSPlayer()
        self.attributed = AttributedString(sampleText)
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

    public func exportVocab() {
        print("Export vocabulary action triggered.")
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
            if let range = newAttributed.range(of: mark.word) {
                newAttributed[range].backgroundColor = .yellow
            }
        }
        self.attributed = newAttributed
    }
}


extension TTSPlayer: TTSPlayerProtocol {
    public var isPlayingPublisher: AnyPublisher<Bool, Never> { $isPlaying.eraseToAnyPublisher() }
    public var currentTimePublisher: AnyPublisher<TimeInterval, Never> { $currentTime.eraseToAnyPublisher() }
}
