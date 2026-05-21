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
}
