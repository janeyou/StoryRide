import Foundation

struct DropboxFile: Identifiable {
    let id: String
    let name: String
    let path: String
    let size: Int64
    let modified: Date
    let contentHash: String

    var displayTitle: String {
        (name as NSString).deletingPathExtension
    }
}
