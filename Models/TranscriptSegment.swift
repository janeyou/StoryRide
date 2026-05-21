import Foundation

struct TranscriptSegment: Codable, Identifiable {
    let text: String
    let startTime: Double
    let endTime: Double

    var id: Double { startTime }

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespaces)
    }

    enum CodingKeys: String, CodingKey {
        case text
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct RivieraTranscriptResponse: Codable {
    let tag: String
    let structuredTranscript: StructuredTranscript?
    let asyncJobId: String?

    enum CodingKeys: String, CodingKey {
        case tag = ".tag"
        case structuredTranscript = "structured_transcript"
        case asyncJobId = "async_job_id"
    }
}

struct StructuredTranscript: Codable {
    let segments: [TranscriptSegment]
}
