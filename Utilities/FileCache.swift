import Foundation

enum FileCache {
    private static var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("StoryRideAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func localURL(for filename: String) -> URL {
        cacheDirectory.appendingPathComponent(filename)
    }

    static func exists(_ filename: String) -> Bool {
        FileManager.default.fileExists(atPath: localURL(for: filename).path)
    }

    static func clearCache() throws {
        let dir = cacheDirectory
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        for file in files {
            try FileManager.default.removeItem(at: file)
        }
    }
}
