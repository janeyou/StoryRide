import Foundation
import SwiftyDropbox
import UIKit

struct DiscoveredFolder: Identifiable, Hashable, Codable {
    let path: String
    let displayName: String
    let fileCount: Int
    var id: String { path }
}

class DropboxService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var filesByFolder: [String: [DropboxFile]] = [:]
    @Published var loadingFolders: Set<String> = []

    @Published var scanInProgress = false
    @Published var discoveredFolders: [DiscoveredFolder] = []
    @Published var lastScanFileCount = 0
    @Published var scanCanContinue = false
    @Published var scanError: String?

    private var folderCounts: [String: Int] = [:]
    private var scanTask: Task<Void, Never>?
    private let scanCursorKey = "dropbox.scanCursor"
    private let scanFoldersKey = "dropbox.scanFolders"
    private let scanFileCountKey = "dropbox.scanFileCount"
    private let scanCanContinueKey = "dropbox.scanCanContinue"
    private let scanFolderCountsKey = "dropbox.scanFolderCounts"

    private static let audioExtensions: Set<String> = ["m4a", "mp3", "wav", "aac"]
    private let audioExtensions = DropboxService.audioExtensions

    init() {
        isAuthenticated = DropboxClientsManager.authorizedClient != nil
        loadPersistedScanState()
    }

    private func loadPersistedScanState() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: scanFoldersKey),
           let folders = try? JSONDecoder().decode([DiscoveredFolder].self, from: data) {
            discoveredFolders = folders
        }
        if let countsData = defaults.data(forKey: scanFolderCountsKey),
           let counts = try? JSONDecoder().decode([String: Int].self, from: countsData) {
            folderCounts = counts
        }
        lastScanFileCount = defaults.integer(forKey: scanFileCountKey)
        scanCanContinue = defaults.bool(forKey: scanCanContinueKey)
    }

    private func persistScanState() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(discoveredFolders) {
            defaults.set(data, forKey: scanFoldersKey)
        }
        if let data = try? JSONEncoder().encode(folderCounts) {
            defaults.set(data, forKey: scanFolderCountsKey)
        }
        defaults.set(lastScanFileCount, forKey: scanFileCountKey)
        defaults.set(scanCanContinue, forKey: scanCanContinueKey)
    }

    private func clearPersistedScanState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: scanFoldersKey)
        defaults.removeObject(forKey: scanFolderCountsKey)
        defaults.removeObject(forKey: scanFileCountKey)
        defaults.removeObject(forKey: scanCanContinueKey)
        defaults.removeObject(forKey: scanCursorKey)
    }

    func authenticate() {
        let scopeRequest = ScopeRequest(
            scopeType: .user,
            scopes: ["files.content.read", "files.content.write"],
            includeGrantedScopes: false
        )
        DropboxClientsManager.authorizeFromControllerV2(
            UIApplication.shared,
            controller: nil,
            loadingStatusDelegate: nil,
            openURL: { url in UIApplication.shared.open(url) },
            scopeRequest: scopeRequest
        )
    }

    func handleRedirect(url: URL) -> Bool {
        let oauthCompletion: DropboxOAuthCompletion = { [weak self] result in
            if case .success = result {
                DispatchQueue.main.async {
                    self?.isAuthenticated = true
                }
            }
        }
        return DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false, completion: oauthCompletion)
    }

    func listAudioFiles(in folderPath: String) async throws {
        guard let client = DropboxClientsManager.authorizedClient else {
            throw StoryRideError.notAuthenticated
        }

        await MainActor.run { _ = loadingFolders.insert(folderPath) }
        defer { Task { @MainActor in loadingFolders.remove(folderPath) } }

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Files.ListFolderResult, Error>) in
            client.files.listFolder(path: folderPath).response { response, error in
                if let response = response {
                    continuation.resume(returning: response)
                } else if let error = error {
                    continuation.resume(throwing: StoryRideError.dropboxError(error.description))
                } else {
                    continuation.resume(throwing: StoryRideError.unknown)
                }
            }
        }

        let audioFiles = result.entries.compactMap { entry -> DropboxFile? in
            guard let file = entry as? Files.FileMetadata else { return nil }
            let ext = (file.name as NSString).pathExtension.lowercased()
            guard audioExtensions.contains(ext) else { return nil }
            return DropboxFile(
                id: file.id,
                name: file.name,
                path: file.pathDisplay ?? file.pathLower ?? "",
                size: Int64(file.size),
                modified: file.serverModified,
                contentHash: file.contentHash ?? ""
            )
        }

        await MainActor.run {
            self.filesByFolder[folderPath] = audioFiles
        }
    }

    func files(in folderPath: String) -> [DropboxFile] {
        filesByFolder[folderPath] ?? []
    }

    /// Lists *immediate* subfolders of the given path (no recursion).
    /// Pass "" for root.
    func listSubfolders(in path: String) async throws -> [String] {
        guard let client = DropboxClientsManager.authorizedClient else {
            throw StoryRideError.notAuthenticated
        }
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Files.ListFolderResult, Error>) in
            client.files.listFolder(path: path, recursive: false).response { response, error in
                if let response { continuation.resume(returning: response) }
                else if let error { continuation.resume(throwing: StoryRideError.dropboxError(error.description)) }
                else { continuation.resume(throwing: StoryRideError.unknown) }
            }
        }
        return result.entries
            .compactMap { ($0 as? Files.FolderMetadata)?.pathDisplay ?? ($0 as? Files.FolderMetadata)?.pathLower }
            .sorted { ($0 as NSString).lastPathComponent.localizedCaseInsensitiveCompare(($1 as NSString).lastPathComponent) == .orderedAscending }
    }

    func isLoading(_ folderPath: String) -> Bool {
        loadingFolders.contains(folderPath)
    }

    func downloadFile(path: String, to localURL: URL) async throws {
        guard let client = DropboxClientsManager.authorizedClient else {
            throw StoryRideError.notAuthenticated
        }

        if FileManager.default.fileExists(atPath: localURL.path) {
            try FileManager.default.removeItem(at: localURL)
        }
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Files.FileMetadata, Error>) in
            client.files.download(path: path, overwrite: true, destination: localURL)
                .response { response, error in
                    if let (metadata, _) = response {
                        continuation.resume(returning: metadata)
                    } else if let error = error {
                        continuation.resume(throwing: StoryRideError.dropboxError(error.description))
                    } else {
                        continuation.resume(throwing: StoryRideError.unknown)
                    }
                }
        }
    }

    func getAccessToken() async -> String? {
        guard let client = DropboxClientsManager.authorizedClient else { return nil }
        return await withCheckedContinuation { continuation in
            client.accessTokenProvider.refreshAccessTokenIfNecessary { _ in
                continuation.resume(returning: client.accessTokenProvider.accessToken)
            }
        }
    }

    func logout() {
        DropboxClientsManager.unlinkClients()
        DispatchQueue.main.async {
            self.clearPersistedScanState()
            self.isAuthenticated = false
            self.filesByFolder = [:]
            self.discoveredFolders = []
            self.folderCounts = [:]
            self.lastScanFileCount = 0
            self.scanCanContinue = false
        }
    }

    // MARK: - Discovery scan

    func startScan(limit: Int = 100) {
        cancelScan()
        Task { @MainActor in
            self.clearPersistedScanState()
            self.discoveredFolders = []
            self.folderCounts = [:]
            self.lastScanFileCount = 0
            self.scanCanContinue = false
            self.scanError = nil
        }
        scanTask = Task { [weak self] in await self?.runScan(resumeWithCursor: false, limit: limit) }
    }

    func continueScan(limit: Int = 100) {
        cancelScan()
        scanTask = Task { [weak self] in await self?.runScan(resumeWithCursor: true, limit: limit) }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        Task { @MainActor in self.scanInProgress = false }
    }

    private func runScan(resumeWithCursor: Bool, limit: Int) async {
        guard let client = DropboxClientsManager.authorizedClient else {
            await MainActor.run { self.scanError = StoryRideError.notAuthenticated.errorDescription }
            return
        }
        await MainActor.run {
            self.scanInProgress = true
            self.scanError = nil
        }
        defer { Task { @MainActor in self.scanInProgress = false } }

        var cursor: String? = resumeWithCursor ? UserDefaults.standard.string(forKey: scanCursorKey) : nil
        var audioSeen = await MainActor.run { self.lastScanFileCount }

        do {
            while true {
                try Task.checkCancellation()
                let result: Files.ListFolderResult
                if let cur = cursor {
                    result = try await listFolderContinue(client: client, cursor: cur)
                } else {
                    result = try await listFolderInitial(client: client)
                }

                let pageAudio = result.entries.compactMap { entry -> (folder: String, name: String)? in
                    guard let file = entry as? Files.FileMetadata else { return nil }
                    let ext = (file.name as NSString).pathExtension.lowercased()
                    guard audioExtensions.contains(ext) else { return nil }
                    let display = file.pathDisplay ?? file.pathLower ?? ""
                    let parent = (display as NSString).deletingLastPathComponent
                    return (parent, file.name)
                }

                audioSeen += pageAudio.count
                await ingest(pageAudio: pageAudio, totalAudio: audioSeen, hasMore: result.hasMore)

                cursor = result.cursor
                UserDefaults.standard.set(result.cursor, forKey: scanCursorKey)

                if !result.hasMore { break }
                if audioSeen >= limit { break }
            }
        } catch is CancellationError {
            // user-cancelled; state already reset
        } catch let err as StoryRideError {
            if case .dropboxError(let msg) = err, msg.contains("reset") {
                UserDefaults.standard.removeObject(forKey: scanCursorKey)
                await MainActor.run { self.scanError = "Scan cursor expired — tap Scan Dropbox to start over." }
            } else {
                await MainActor.run { self.scanError = err.errorDescription }
            }
        } catch {
            await MainActor.run { self.scanError = error.localizedDescription }
        }
    }

    @MainActor
    private func ingest(pageAudio: [(folder: String, name: String)], totalAudio: Int, hasMore: Bool) {
        for item in pageAudio {
            folderCounts[item.folder, default: 0] += 1
        }
        discoveredFolders = folderCounts
            .map { DiscoveredFolder(
                path: $0.key,
                displayName: ($0.key as NSString).lastPathComponent.isEmpty ? "/" : ($0.key as NSString).lastPathComponent,
                fileCount: $0.value
            ) }
            .sorted { ($0.fileCount, $1.displayName) > ($1.fileCount, $0.displayName) }
        lastScanFileCount = totalAudio
        scanCanContinue = hasMore && totalAudio >= 1
        persistScanState()
    }

    private func listFolderInitial(client: DropboxClient) async throws -> Files.ListFolderResult {
        try await withCheckedThrowingContinuation { continuation in
            client.files.listFolder(
                path: "",
                recursive: true,
                includeMediaInfo: false,
                includeDeleted: false,
                includeHasExplicitSharedMembers: false,
                limit: 2000
            ).response { response, error in
                if let response { continuation.resume(returning: response) }
                else if let error { continuation.resume(throwing: StoryRideError.dropboxError(error.description)) }
                else { continuation.resume(throwing: StoryRideError.unknown) }
            }
        }
    }

    private func listFolderContinue(client: DropboxClient, cursor: String) async throws -> Files.ListFolderResult {
        try await withCheckedThrowingContinuation { continuation in
            client.files.listFolderContinue(cursor: cursor).response { response, error in
                if let response { continuation.resume(returning: response) }
                else if let error { continuation.resume(throwing: StoryRideError.dropboxError(error.description)) }
                else { continuation.resume(throwing: StoryRideError.unknown) }
            }
        }
    }
}

enum StoryRideError: LocalizedError {
    case notAuthenticated
    case dropboxError(String)
    case transcriptionFailed(String)
    case audioNotFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated with Dropbox"
        case .dropboxError(let msg): return "Dropbox error: \(msg)"
        case .transcriptionFailed(let msg): return "Transcription failed: \(msg)"
        case .audioNotFound: return "Audio file not found"
        case .unknown: return "An unknown error occurred"
        }
    }
}
