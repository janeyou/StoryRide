import Foundation
import SwiftData

@Model
class StoryRecord {
    @Attribute(.unique) var dropboxFileId: String = ""
    var title: String = ""
    var dropboxPath: String = ""
    var contentHash: String = ""
    var localAudioPath: String?
    var duration: TimeInterval = 0
    var lastPosition: TimeInterval = 0
    var isStarred: Bool = false
    var createdAt: Date = Date()
    var lastPlayedAt: Date?

    init(
        dropboxFileId: String,
        title: String,
        dropboxPath: String,
        contentHash: String,
        duration: TimeInterval = 0
    ) {
        self.dropboxFileId = dropboxFileId
        self.title = title
        self.dropboxPath = dropboxPath
        self.contentHash = contentHash
        self.duration = duration
    }

    /// Parent Dropbox folder path (e.g. `/Music/Bedtime` for a file at `/Music/Bedtime/owl.mp3`).
    var parentFolderPath: String {
        (dropboxPath as NSString).deletingLastPathComponent
    }

    /// 0...1 listened fraction. 0 if duration is unknown.
    var listenedFraction: Double {
        guard duration > 0 else { return 0 }
        return min(max(lastPosition / duration, 0), 1)
    }
}
