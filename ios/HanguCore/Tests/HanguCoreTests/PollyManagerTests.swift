import XCTest
@testable import HanguCore
import AWSCore
import AWSPolly

// A mock URL builder that intercepts requests and returns URLs to local test files
// instead of hitting the network. This is a form of dependency injection for testing.
private class MockPollyURLBuilder: AWSPollySynthesizeSpeechURLBuilder {
    enum MockError: Error { case unsupportedFormat }

    override func getPreSignedURL(_ request: AWSPollySynthesizeSpeechURLBuilderRequest!) -> AWSTask<NSURL> {
        let taskCompletionSource = AWSTaskCompletionSource<NSURL>()
        
        let resourceName: String
        let fileExtension: String
        
        // Return a different local file based on the output format requested.
        switch request.outputFormat {
        case .mp3:
            // We don't need a real MP3 for this test, just a valid file URL.
            // The speech marks JSON serves as a valid stand-in file.
            resourceName = "SampleSpeechMarks"
            fileExtension = "json"
        case .json:
            resourceName = "SampleSpeechMarks"
            fileExtension = "json"
        default:
            taskCompletionSource.set(error: MockError.unsupportedFormat)
            return taskCompletionSource.task
        }

        // Find the resource in the test bundle.
        if let url = Bundle(for: PollyManagerTests.self).url(forResource: resourceName, withExtension: fileExtension, subdirectory: "shared/samples") {
            taskCompletionSource.set(result: url as NSURL)
        } else {
            let error = NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Mock file not found: \(resourceName).\(fileExtension)"])
            taskCompletionSource.set(error: error)
        }
        
        return taskCompletionSource.task
    }
}

final class PollyManagerTests: XCTestCase {

    private var pollyManager: PollyManager!

    override func setUp() {
        super.setUp()
        // To inject our mock, we create a testable subclass of PollyManager
        // that replaces the real URL builder with our mock instance.
        class TestablePollyManager: PollyManager {
            override init() {
                super.init()
                self.urlBuilder = MockPollyURLBuilder()
            }
        }
        pollyManager = TestablePollyManager()
    }

    func testSynthesize_SuccessfullyFetchesAndParsesMarks() {
        let expectation = self.expectation(description: "Synthesize completes and parses speech marks correctly")
        let testText = "안녕하세요, 만나서 반갑습니다."

        pollyManager.synthesize(text: testText) { result in
            switch result {
            case .success((let audioURL, let marks)):
                // 1. Verify we received a valid file URL for the audio.
                XCTAssertTrue(FileManager.default.fileExists(atPath: audioURL.path), "Audio URL should point to a valid temporary file.")
                
                // 2. Verify the speech marks were parsed correctly from the sample JSON.
                // The sample file contains one sentence mark and three word marks.
                XCTAssertEqual(marks.count, 3, "Should parse exactly 3 'word' type speech marks.")
                
                XCTAssertEqual(marks[0].word, "안녕하세요")
                XCTAssertEqual(marks[0].startMs, 103)
                XCTAssertEqual(marks[0].charStart, 0)
                XCTAssertEqual(marks[0].charEnd, 5)

                XCTAssertEqual(marks[1].word, "만나서")
                XCTAssertEqual(marks[1].startMs, 701)
                
                XCTAssertEqual(marks[2].word, "반갑습니다")
                XCTAssertEqual(marks[2].startMs, 1137)

            case .failure(let error):
                XCTFail("Synthesis failed unexpectedly with error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }
}