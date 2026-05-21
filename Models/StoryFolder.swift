import Foundation
import SwiftData

@Model
class StoryFolder {
    @Attribute(.unique) var dropboxPath: String = ""
    var displayName: String = ""
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(dropboxPath: String, displayName: String, sortOrder: Int = 0) {
        self.dropboxPath = dropboxPath
        self.displayName = displayName
        self.sortOrder = sortOrder
    }
}
