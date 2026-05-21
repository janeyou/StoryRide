import SwiftUI
import SwiftData

struct LibraryView: View {
    @EnvironmentObject var dropboxService: DropboxService
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoryFolder.sortOrder) private var folders: [StoryFolder]
    @State private var selectedFolderIndex: Int = 0
    @State private var errorMessage: String?
    @State private var selectedFile: DropboxFile?
    @State private var showDiscover = false
    @State private var showAddFolder = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.bg.ignoresSafeArea()

                if folders.isEmpty {
                    emptyFoldersState
                } else {
                    TabView(selection: $selectedFolderIndex) {
                        ForEach(Array(folders.enumerated()), id: \.element.dropboxPath) { index, folder in
                            FolderPage(
                                folder: folder,
                                onSelect: { selectedFile = $0 }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("StoryRide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(Theme.Color.textStrong)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationDestination(item: $selectedFile) { file in
                PlayerView(file: file)
                    .environmentObject(dropboxService)
            }
            .sheet(isPresented: $showDiscover) {
                DiscoverFoldersSheet()
                    .environmentObject(dropboxService)
            }
            .sheet(isPresented: $showAddFolder) {
                AddFolderSheet { name, path in
                    let order = (folders.last?.sortOrder ?? -1) + 1
                    modelContext.insert(StoryFolder(dropboxPath: path, displayName: name, sortOrder: order))
                    try? modelContext.save()
                }
                .environmentObject(dropboxService)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyFoldersState: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(Theme.Color.textFaint)
            VStack(spacing: 6) {
                Text("No playlists yet")
                    .font(Theme.Font.display(24, weight: .regular))
                    .foregroundColor(Theme.Color.textStrong)
                Text("Scan your Dropbox for audio, or add a folder by path.")
                    .font(Theme.Font.body(15))
                    .foregroundColor(Theme.Color.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    showDiscover = true
                } label: {
                    Text("Scan Dropbox")
                        .font(Theme.Font.display(17, weight: .medium))
                        .foregroundColor(Theme.Color.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Theme.Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }

                Button {
                    showAddFolder = true
                } label: {
                    Text("Add a folder")
                        .font(Theme.Font.label(14))
                        .foregroundColor(Theme.Color.text)
                }
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}

private struct FolderPage: View {
    let folder: StoryFolder
    let onSelect: (DropboxFile) -> Void
    @EnvironmentObject var dropboxService: DropboxService
    @State private var didLoad = false
    @State private var loadError: String?

    var body: some View {
        let files = dropboxService.files(in: folder.dropboxPath)
        let isLoading = dropboxService.isLoading(folder.dropboxPath)

        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PLAYLIST")
                    .font(Theme.Font.label(11))
                    .tracking(2)
                    .foregroundColor(Theme.Color.textMuted)
                Text(folder.displayName)
                    .font(Theme.Font.display(34, weight: .regular))
                    .foregroundColor(Theme.Color.textStrong)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 20)

            if let loadError {
                ErrorBanner(message: loadError) { Task { await reload() } }
            } else if isLoading && files.isEmpty {
                Spacer()
                ProgressView().tint(Theme.Color.text)
                Spacer()
            } else if files.isEmpty {
                emptyFolderState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(files) { file in
                            FileRow(file: file)
                                .onTapGesture { onSelect(file) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 60)
                }
                .refreshable { await reload() }
            }
        }
        .task(id: folder.dropboxPath) {
            guard !didLoad else { return }
            didLoad = true
            await reload()
        }
    }

    private var emptyFolderState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "music.note")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Theme.Color.textFaint)
            Text("No audio in this folder")
                .font(Theme.Font.body(17))
                .foregroundColor(Theme.Color.textMuted)
            Button("Refresh") { Task { await reload() } }
                .font(Theme.Font.label(14))
                .foregroundColor(Theme.Color.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func reload() async {
        do {
            loadError = nil
            try await dropboxService.listAudioFiles(in: folder.dropboxPath)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct ErrorBanner: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .font(Theme.Font.body(15))
                .foregroundColor(Theme.Color.text)
            Button("Retry", action: retry)
                .font(Theme.Font.label(14))
                .foregroundColor(Theme.Color.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.bgElev)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .padding(.horizontal, 16)
    }
}

struct FileRow: View {
    let file: DropboxFile

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Color.accentSoft)
                    .frame(width: 52, height: 52)
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Color.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(file.displayTitle)
                    .font(Theme.Font.display(20, weight: .regular))
                    .foregroundColor(Theme.Color.textStrong)
                    .lineLimit(1)

                if TranscriptStore.exists(hash: file.contentHash) {
                    Text("transcribed")
                        .font(Theme.Font.label(12))
                        .foregroundColor(Theme.Color.textMuted)
                } else {
                    Text("tap to play")
                        .font(Theme.Font.label(12))
                        .foregroundColor(Theme.Color.textFaint)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Theme.Color.textFaint)
        }
        .padding(16)
        .frame(minHeight: 84)
        .background(Theme.Color.bgElev)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

extension DropboxFile: Hashable {
    static func == (lhs: DropboxFile, rhs: DropboxFile) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
