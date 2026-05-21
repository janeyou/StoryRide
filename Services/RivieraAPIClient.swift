import Foundation

class RivieraAPIClient {
    private let baseURL = "https://api.dropboxapi.com/2/riviera"
    private let pollInterval: TimeInterval = 15

    func transcribe(filePath: String, token: String) async throws -> [TranscriptSegment] {
        switch try await submitJob(filePath: filePath, token: token) {
        case .complete(let segments):
            return segments
        case .pending(let jobId):
            return try await pollForResult(jobId: jobId, token: token)
        }
    }

    private enum SubmitResult {
        case complete([TranscriptSegment])
        case pending(String)
    }

    private func submitJob(filePath: String, token: String) async throws -> SubmitResult {
        let url = URL(string: "\(baseURL)/get_transcript_async")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "file_id_or_url": [
                ".tag": "path",
                "path": filePath
            ],
            "timestamp_level": "word"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StoryRideError.unknown
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
            throw StoryRideError.transcriptionFailed("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        let decoded = try JSONDecoder().decode(RivieraTranscriptResponse.self, from: data)

        switch decoded.tag {
        case "async_job_id":
            guard let jobId = decoded.asyncJobId else {
                throw StoryRideError.transcriptionFailed("No job ID in response")
            }
            return .pending(jobId)
        case "complete":
            return .complete(decoded.structuredTranscript?.segments ?? [])
        default:
            throw StoryRideError.transcriptionFailed("Unexpected tag: \(decoded.tag)")
        }
    }

    private func pollForResult(jobId: String, token: String) async throws -> [TranscriptSegment] {
        let url = URL(string: "\(baseURL)/get_transcript_async/check")!

        while true {
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["async_job_id": jobId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw StoryRideError.unknown
            }

            if httpResponse.statusCode == 429 {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    .flatMap(Double.init) ?? 30
                try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                continue
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
                throw StoryRideError.transcriptionFailed("Poll HTTP \(httpResponse.statusCode): \(errorBody)")
            }

            let decoded = try JSONDecoder().decode(RivieraTranscriptResponse.self, from: data)

            if decoded.tag == "complete" {
                return decoded.structuredTranscript?.segments ?? []
            }
        }
    }
}

