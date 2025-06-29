import XCTest
@testable import HanguCore
import Combine
import SwiftUI

// A mock PollyManager that returns predictable, local data for tests.
private class MockPollyManager: PollyManager {
    override func synthesize(text: String, voiceId: AWSPollyVoiceId, completion: @escaping (Result<(audio: URL, marks: [SpeechMark]), Error>) -> Void) {
        guard let audioURL = Bundle(for: ReaderViewModelTests.self).url(forResource: "SampleSpeechMarks", withExtension: "json", subdirectory: "shared/samples"),
              let marksURL = Bundle(for: ReaderViewModelTests.self).url(forResource: "SampleSpeechMarks", withExtension: "json", subdirectory: "shared/samples") else {
            let error = NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Test resources not found."])
            completion(.failure(error))
            return
        }
        let marksData = try! Data(contentsOf: marksURL)
        let marks = SpeechMark.parseLines(from: marksData)
        completion(.success((audio: audioURL, marks: marks)))
    }
}

// A mock TTSPlayer that allows us to manually control playback state and time.
private class MockTTSPlayer: TTSPlayer {
    // We expose the Combine publisher publicly for tests to emit values.
    public let currentTimePublisher = PassthroughSubject<TimeInterval, Never>()
    
    override var currentTime: TimeInterval {
        get { super.currentTime }
        set { super.currentTime = newValue }
    }
    
    override func play(url: URL) {
        self.isPlaying = true
    }
    
    override func pause() {
        self.isPlaying = false
    }
    
    override func resume() {
        self.isPlaying = true
    }
}

@MainActor
final class ReaderViewModelTests: XCTestCase {

    private var viewModel: ReaderViewModel!
    private var mockPollyManager: MockPollyManager!
    private var mockTTSPlayer: MockTTSPlayer!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockPollyManager = MockPollyManager()
        mockTTSPlayer = MockTTSPlayer()
        // Inject the mock dependencies into the view model.
        viewModel = ReaderViewModel(text: "안녕하세요, 만나서 반갑습니다.", pollyManager: mockPollyManager, ttsPlayer: mockTTSPlayer)
        cancellables = []
    }

    func testCurrentWordIndex_AdvancesWithTime() {
        let expectation = self.expectation(description: "currentWordIndex updates as currentTime changes")
        
        // Wait for the initial data fetch to complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 1. Before any time has passed, no word should be highlighted.
            XCTAssertEqual(self.viewModel.currentWordIndex, -1, "Pre-condition: No word should be highlighted initially.")
            
            // 2. Simulate time advancing to 800ms.
            self.mockTTSPlayer.currentTimePublisher.send(0.8)
            
            // The second word ("만나서") starts at 701ms.
            XCTAssertEqual(self.viewModel.currentWordIndex, 1, "Index should advance to the second word.")
            
            // 3. Simulate time advancing to 1200ms.
            self.mockTTSPlayer.currentTimePublisher.send(1.2)
            
            // The third word ("반갑습니다") starts at 1137ms.
            XCTAssertEqual(self.viewModel.currentWordIndex, 2, "Index should advance to the third word.")
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
}

// To make this test compile, the ReaderViewModel initializer must be updated to allow
// injecting a TTSPlayer, like so:
//
// public init(text: String,
//             pollyManager: PollyManager = PollyManager(),
//             ttsPlayer: TTSPlayer = TTSPlayer()) { ... }