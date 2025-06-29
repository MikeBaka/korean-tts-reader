// PASTE THIS INTO SpeechMark.swift

import Foundation

public struct SpeechMark: Decodable, Equatable {
    public let word: String
    public let startMs: Int
    public let charStart: Int
    public let charEnd: Int

    // Polly returns a stream of JSON objects, one per line.
    // This private struct is used to decode the raw data before filtering.
    private struct PollySpeechMark: Decodable {
        let time: Int
        let type: String
        let start: Int
        let end: Int
        let value: String
    }

    public static func parseLines(from data: Data) -> [SpeechMark] {
        guard let text = String(data: data, encoding: .utf8) else { return [] }
        let lines = text.split(separator: "\n")
        let decoder = JSONDecoder()

        return lines.compactMap { line in
            guard let lineData = String(line).data(using: .utf8),
                  let pollyMark = try? decoder.decode(PollySpeechMark.self, from: lineData),
                  pollyMark.type == "word" else {
                return nil
            }
            return SpeechMark(
                word: pollyMark.value,
                startMs: pollyMark.time,
                charStart: pollyMark.start,
                charEnd: pollyMark.end
            )
        }
    }
}
