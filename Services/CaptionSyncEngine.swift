import Foundation
import SwiftUI

class CaptionSyncEngine: ObservableObject {
    @Published var visibleWords: [CaptionWord] = []
    @Published var currentWordIndex: Int = 0

    private var segments: [TranscriptSegment] = []
    private let windowSize = 12

    func load(segments: [TranscriptSegment]) {
        self.segments = segments
        currentWordIndex = 0
        updateVisible()
    }

    func update(currentTime: TimeInterval) {
        let newIndex = findCurrentIndex(time: currentTime)
        if newIndex != currentWordIndex {
            currentWordIndex = newIndex
            updateVisible()
        }
    }

    private func findCurrentIndex(time: TimeInterval) -> Int {
        var low = 0
        var high = segments.count - 1

        while low <= high {
            let mid = (low + high) / 2
            if segments[mid].startTime <= time {
                if mid == segments.count - 1 || segments[mid + 1].startTime > time {
                    return mid
                }
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return max(0, low)
    }

    private func updateVisible() {
        guard !segments.isEmpty else {
            visibleWords = []
            return
        }

        let start = max(0, currentWordIndex - windowSize / 3)
        let end = min(segments.count, start + windowSize)

        visibleWords = (start..<end).map { index in
            CaptionWord(
                text: segments[index].trimmedText,
                isActive: index == currentWordIndex,
                index: index
            )
        }
    }

    func reset() {
        segments = []
        currentWordIndex = 0
        visibleWords = []
    }
}

struct CaptionWord: Identifiable {
    let text: String
    let isActive: Bool
    let index: Int

    var id: Int { index }
}
