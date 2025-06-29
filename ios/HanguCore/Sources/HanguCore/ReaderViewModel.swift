import Foundation
import Combine
import SwiftUI

@MainActor
public final class ReaderViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published public var attributed: AttributedString
    @Published public var isPlaying: Bool = false

    // MARK: - Public Properties
    public var vocab: Set<String> = []
    
    // MARK: - Internal Properties for Testing
    var speechMarks: [SpeechMark] = []
    var currentWordIndex: Int = -1 {
        didSet {
            if oldValue != currentWordIndex {
                updateAttributedString()
            }
        }
    }

    // MARK: - Private Properties
    private let originalText: String
    private let pollyManager: PollyManager
    private let ttsPlayer: TTSPlayer

    private var audioURL: URL?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    // The initializer now accepts both a PollyManager and a TTSPlayer for full
    // dependency injection during testing.
    public init(text: String, pollyManager: PollyManager = PollyManager(), ttsPlayer: TTSPlayer = TTSPlayer()) {
        self.originalText = text
        self.attributed = AttributedString(text)
        self.pollyManager = pollyManager
        self.ttsPlayer = ttsPlayer

        setupBindings()
        synthesizeText()
    }

    // MARK: - Public Methods
    public func togglePlay() {
        guard audioURL != nil else { return }

        if ttsPlayer.isPlaying {
            ttsPlayer.pause()
        } else {
            if ttsPlayer.currentTime > 0 {
                ttsPlayer.resume()
            } else if let url = self.audioURL {
                ttsPlayer.play(url: url)
            }
        }
    }

    public func exportVocab() {
        VocabularyExporter.share(vocab)
    }

    // MARK: - Private & Internal Methods
    private func setupBindings() {
        // When testing with a mock player, we might need to manually publish changes.
        // This setup handles both the real player's @Published property and a mock's PassthroughSubject.
        let isPlayingPublisher = (ttsPlayer as? MockTTSPlayer)?.isPlayingPublisher ?? ttsPlayer.$isPlaying.eraseToAnyPublisher()
        let currentTimePublisher = (ttsPlayer as? MockTTSPlayer)?.currentTimePublisher ?? ttsPlayer.$currentTime.eraseToAnyPublisher()

        isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)

        currentTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTime in
                self?.updateHighlight(at: newTime)
            }
            .store(in: &cancellables)
    }

    private func synthesizeText() {
        pollyManager.synthesize(text: originalText) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success((let audioURL, let marks)):
                self.audioURL = audioURL
                self.speechMarks = marks
                self.buildVocabulary()
            case .failure(let error):
                print("Synthesis failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func buildVocabulary() {
        let words = speechMarks.map { $0.word }
        let cleanedWords = words.map { $0.trimmingCharacters(in: .punctuationCharacters) }
        self.vocab = Set(cleanedWords.filter { !$0.isEmpty })
    }

    func updateHighlight(at time: TimeInterval) {
        let timeInMs = Int(time * 1000)
        
        guard let newIndex = speechMarks.lastIndex(where: { $0.startMs <= timeInMs }) else {
            if currentWordIndex != -1 {
                currentWordIndex = -1
            }
            return
        }

        if newIndex != currentWordIndex {
            currentWordIndex = newIndex
        }
    }

    private func updateAttributedString() {
        var newAttributedString = AttributedString(originalText)

        if currentWordIndex >= 0 && currentWordIndex < speechMarks.count {
            let mark = speechMarks[currentWordIndex]
            
            if let range = Range(NSRange(location: mark.charStart, length: mark.charEnd - mark.charStart), in: originalText) {
                if let attrRange = newAttributedString.range(of: originalText[range]) {
                    let bodySize = UIFont.preferredFont(forTextStyle: .body).pointSize
                    newAttributedString[attrRange].font = .system(size: bodySize, weight: .bold)
                    newAttributedString[attrRange].foregroundColor = .blue
                }
            }
        }
        self.attributed = newAttributedString
    }
}

// Helper protocol and extension to allow mocking both @Published and PassthroughSubject publishers
// This is a more robust way to handle testing with Combine.
fileprivate protocol TTSPlayerProtocol {
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
}

extension TTSPlayer: TTSPlayerProtocol {
    var isPlayingPublisher: AnyPublisher<Bool, Never> { $isPlaying.eraseToAnyPublisher() }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { $currentTime.eraseToAnyPublisher() }
}

