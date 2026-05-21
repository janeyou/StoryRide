import Foundation
import os

enum TranscriptStore {
    private static let log = Logger(subsystem: "com.janeyou.storyride", category: "TranscriptStore")

    private static var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Transcripts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func url(for hash: String) -> URL {
        directory.appendingPathComponent("\(hash).json")
    }

    static func exists(hash: String) -> Bool {
        guard !hash.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: url(for: hash).path)
    }

    static func load(hash: String) -> [TranscriptSegment]? {
        guard !hash.isEmpty else { return nil }
        let path = url(for: hash)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        do {
            let data = try Data(contentsOf: path)
            return try JSONDecoder().decode([TranscriptSegment].self, from: data)
        } catch {
            log.error("transcript decode failed for \(hash): \(error.localizedDescription)")
            return nil
        }
    }

    static func save(_ segments: [TranscriptSegment], hash: String) throws {
        guard !hash.isEmpty else { return }
        let data = try JSONEncoder().encode(segments)
        try data.write(to: url(for: hash), options: .atomic)
    }
}
