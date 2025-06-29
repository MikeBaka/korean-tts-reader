import Foundation
import AWSPolly
import AVFoundation

public final class PollyManager {

    private let polly: AWSPolly
    private let urlBuilder: AWSPollySynthesizeSpeechURLBuilder

    public init() {
        let credentialsProvider = Config.credentialProvider()
        let configuration = AWSServiceConfiguration(
            region: Config.pollyRegion(),
            credentialsProvider: credentialsProvider
        )
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        self.polly = AWSPolly.default()
        self.urlBuilder = AWSPollySynthesizeSpeechURLBuilder.default()
    }

    public func synthesize(
        text: String,
        voiceId: AWSPollyVoiceId = .seoyeon,
        completion: @escaping (Result<(audio: URL, marks: [SpeechMark]), Error>) -> Void
    ) {
        let group = DispatchGroup()
        var audioURL: URL?
        var speechMarks: [SpeechMark]?
        var capturedError: Error?

        // 1. Get Audio URL
        group.enter()
        let audioRequest = AWSPollySynthesizeSpeechURLBuilderRequest()
        audioRequest.text = text
        audioRequest.outputFormat = .mp3
        audioRequest.voiceId = voiceId

        urlBuilder.getPreSignedURL(audioRequest).continueWith { task -> Any? in
            defer { group.leave() }
            if let error = task.error {
                capturedError = error
                return nil
            }
            if let presignedURL = task.result {
                // Download the audio data
                group.enter()
                URLSession.shared.dataTask(with: presignedURL) { data, _, error in
                    defer { group.leave() }
                    if let error = error {
                        capturedError = error
                        return
                    }
                    if let data = data {
                        // Save to a temporary file
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp3")
                        do {
                            try data.write(to: tempURL)
                            audioURL = tempURL
                        } catch {
                            capturedError = error
                        }
                    }
                }.resume()
            }
            return nil
        }

        // 2. Get Speech Marks
        group.enter()
        let marksRequest = AWSPollySynthesizeSpeechURLBuilderRequest()
        marksRequest.text = text
        marksRequest.outputFormat = .json
        marksRequest.voiceId = voiceId
        marksRequest.speechMarkTypes = ["word"]

        urlBuilder.getPreSignedURL(marksRequest).continueWith { task -> Any? in
            defer { group.leave() }
            if let error = task.error {
                capturedError = error
                return nil
            }
            if let presignedURL = task.result {
                // Download the speech mark data
                group.enter()
                URLSession.shared.dataTask(with: presignedURL) { data, _, error in
                    defer { group.leave() }
                    if let error = error {
                        capturedError = error
                        return
                    }
                    if let data = data {
                        speechMarks = SpeechMark.parseLines(from: data)
                    }
                }.resume()
            }
            return nil
        }

        // 3. Notify on completion
        group.notify(queue: .main) {
            if let error = capturedError {
                completion(.failure(error))
                return
            }

            guard let finalAudioURL = audioURL, let finalSpeechMarks = speechMarks else {
                let error = NSError(domain: "PollyManagerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve audio or speech marks."])
                completion(.failure(error))
                return
            }

            completion(.success((audio: finalAudioURL, marks: finalSpeechMarks)))
        }
    }
}