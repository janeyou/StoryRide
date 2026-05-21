import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var dropboxService: DropboxService
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoryFolder.sortOrder) private var folders: [StoryFolder]
    @AppStorage("captionFontSize") private var captionFontSize: Double = 48
    @State private var showAddFolder = false
    @State private var showDiscover = false

    var body: some View {
        ZStack {
            Theme.Color.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    accountSection
                    playlistsSection
                    captionsSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Settings")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddFolder) {
            AddFolderSheet { name, path in
                let order = (folders.last?.sortOrder ?? -1) + 1
                modelContext.insert(StoryFolder(dropboxPath: path, displayName: name, sortOrder: order))
                try? modelContext.save()
            }
            .environmentObject(dropboxService)
        }
        .sheet(isPresented: $showDiscover) {
            DiscoverFoldersSheet()
                .environmentObject(dropboxService)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ABOUT")
            Text("StoryRide")
                .font(Theme.Font.display(28, weight: .regular))
                .foregroundColor(Theme.Color.textStrong)
            Text("Audio stories and songs from your Dropbox, with big synced captions on screen. Built for toddlers who want their favorites in the car — read while listening, glance at a giant play button, never fumble.")
                .font(Theme.Font.body(15))
                .foregroundColor(Theme.Color.text)
                .lineSpacing(4)
            Text("Version 1.0.0")
                .font(Theme.Font.label(12))
                .foregroundColor(Theme.Color.textMuted)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.bgElev)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                sectionLabel("PLAYLISTS")
                Spacer()
                Button {
                    showDiscover = true
                } label: {
                    Label("Scan", systemImage: "sparkle.magnifyingglass")
                        .font(Theme.Font.label(13))
                        .foregroundColor(Theme.Color.accent)
                }
                Button {
                    showAddFolder = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(Theme.Font.label(13))
                        .foregroundColor(Theme.Color.text)
                }
            }
            .padding(.horizontal, 4)

            if folders.isEmpty {
                Text("No folders yet. Scan your Dropbox to find audio, or add a folder by path.")
                    .font(Theme.Font.body(14))
                    .foregroundColor(Theme.Color.textMuted)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Color.bgElev)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            } else {
                VStack(spacing: 8) {
                    ForEach(folders) { folder in
                        FolderRow(folder: folder) {
                            modelContext.delete(folder)
                            try? modelContext.save()
                        }
                    }
                }
            }
        }
    }

    private var captionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("CAPTIONS")
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Font size")
                        .font(Theme.Font.body(15))
                        .foregroundColor(Theme.Color.text)
                    Spacer()
                    Text("\(Int(captionFontSize)) pt")
                        .font(Theme.Font.label(13))
                        .foregroundColor(Theme.Color.textMuted)
                }
                Slider(value: $captionFontSize, in: 36...72, step: 4)
                    .tint(Theme.Color.accent)
                Text("the quick brown fox")
                    .font(.system(size: captionFontSize, weight: .light, design: .rounded))
                    .foregroundColor(Theme.Color.accent)
                    .padding(.top, 8)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Color.bgElev)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("ACCOUNT")
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Theme.Color.accent)
                        .frame(width: 8, height: 8)
                    Text("Dropbox connected")
                        .font(Theme.Font.body(15))
                        .foregroundColor(Theme.Color.text)
                }
                Button {
                    dropboxService.logout()
                } label: {
                    Text("Disconnect")
                        .font(Theme.Font.label(13))
                        .foregroundColor(Theme.Color.accent)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Color.bgElev)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.label(11))
            .tracking(2)
            .foregroundColor(Theme.Color.textMuted)
            .padding(.horizontal, 4)
    }
}

private struct FolderRow: View {
    let folder: StoryFolder
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.displayName)
                    .font(Theme.Font.body(16, weight: .regular))
                    .foregroundColor(Theme.Color.textStrong)
                Text(folder.dropboxPath)
                    .font(Theme.Font.label(11))
                    .foregroundColor(Theme.Color.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Theme.Color.textMuted)
            }
        }
        .padding(16)
        .background(Theme.Color.bgElev)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

struct AddFolderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dropboxService: DropboxService
    @Query private var existingFolders: [StoryFolder]
    let onAdd: (_ name: String, _ path: String) -> Void

    @State private var currentPath: String = ""
    @State private var subfolders: [String] = []
    @State private var loading = false
    @State private var error: String?
    @State private var displayName: String = ""
    @State private var nameEdited = false

    private var existingPaths: Set<String> {
        Set(existingFolders.map { $0.dropboxPath })
    }

    private var pathDisplay: String {
        currentPath.isEmpty ? "/" : currentPath
    }

    private var isAtRoot: Bool { currentPath.isEmpty }

    private var canAdd: Bool {
        !isAtRoot &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !existingPaths.contains(currentPath)
    }

    var body: some View {
        ZStack {
            Theme.Color.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                Divider()
                    .overlay(Theme.Color.border)

                browserBody

                Spacer(minLength: 0)

                footer
            }
        }
        .preferredColorScheme(.dark)
        .task { await load(path: "") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Add a playlist")
                    .font(Theme.Font.display(22, weight: .regular))
                    .foregroundColor(Theme.Color.textStrong)
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(Theme.Font.label(14))
                    .foregroundColor(Theme.Color.text)
            }

            HStack(spacing: 10) {
                Button {
                    Task { await navigateUp() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isAtRoot ? Theme.Color.textFaint : Theme.Color.text)
                        .frame(width: 32, height: 32)
                        .background(Theme.Color.bgElev)
                        .clipShape(Circle())
                }
                .disabled(isAtRoot)

                Text(pathDisplay)
                    .font(Theme.Font.label(13))
                    .foregroundColor(Theme.Color.textMuted)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private var browserBody: some View {
        Group {
            if loading {
                Spacer()
                ProgressView().tint(Theme.Color.text)
                Spacer()
            } else if let error {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error)
                        .font(Theme.Font.body(14))
                        .foregroundColor(Theme.Color.accent)
                    Button("Retry") { Task { await load(path: currentPath) } }
                        .font(Theme.Font.label(13))
                        .foregroundColor(Theme.Color.accent)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Color.bgElev)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                .padding(.horizontal, 20)
            } else if subfolders.isEmpty {
                Spacer()
                Text(isAtRoot ? "No folders found in your Dropbox" : "No subfolders here")
                    .font(Theme.Font.body(14))
                    .foregroundColor(Theme.Color.textMuted)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(subfolders, id: \.self) { path in
                            folderRow(path: path)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private func folderRow(path: String) -> some View {
        let name = (path as NSString).lastPathComponent
        let isExisting = existingPaths.contains(path)
        return Button {
            Task { await load(path: path) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "folder")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Theme.Color.accent)
                Text(name)
                    .font(Theme.Font.body(16, weight: .regular))
                    .foregroundColor(Theme.Color.textStrong)
                    .lineLimit(1)
                Spacer()
                if isExisting {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Color.textFaint)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Theme.Color.textFaint)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Color.bgElev)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !isAtRoot {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DISPLAY NAME")
                        .font(Theme.Font.label(11))
                        .tracking(2)
                        .foregroundColor(Theme.Color.textMuted)
                    TextField("", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .font(Theme.Font.body(16))
                        .foregroundColor(Theme.Color.textStrong)
                        .padding(12)
                        .background(Theme.Color.bgElev)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                        .onChange(of: displayName) { _, _ in nameEdited = true }
                }
            }

            Button {
                guard canAdd else { return }
                onAdd(displayName.trimmingCharacters(in: .whitespaces), currentPath)
                dismiss()
            } label: {
                Text(addButtonLabel)
                    .font(Theme.Font.display(16, weight: .medium))
                    .foregroundColor(canAdd ? Theme.Color.bg : Theme.Color.textMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canAdd ? Theme.Color.accent : Theme.Color.bgElev)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            .disabled(!canAdd)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 12)
    }

    private var addButtonLabel: String {
        if isAtRoot { return "Pick a folder" }
        if existingPaths.contains(currentPath) { return "Already added" }
        return "Add this folder"
    }

    private func load(path: String) async {
        loading = true
        error = nil
        do {
            let folders = try await dropboxService.listSubfolders(in: path)
            currentPath = path
            subfolders = folders
            if !nameEdited && !path.isEmpty {
                displayName = (path as NSString).lastPathComponent
            }
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private func navigateUp() async {
        guard !isAtRoot else { return }
        let parent = (currentPath as NSString).deletingLastPathComponent
        // Dropbox API uses "" for root, not "/"
        let nextPath = (parent == "/" || parent.isEmpty) ? "" : parent
        await load(path: nextPath)
    }
}

struct DiscoverFoldersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var dropboxService: DropboxService
    @Query(sort: \StoryFolder.sortOrder) private var existingFolders: [StoryFolder]
    @State private var selected: Set<String> = []

    private var existingPaths: Set<String> {
        Set(existingFolders.map { $0.dropboxPath })
    }

    private var hasResults: Bool { !dropboxService.discoveredFolders.isEmpty }

    var body: some View {
        ZStack {
            Theme.Color.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                if let err = dropboxService.scanError {
                    Text(err)
                        .font(Theme.Font.body(14))
                        .foregroundColor(Theme.Color.accent)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Color.bgElev)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }

                if !hasResults && !dropboxService.scanInProgress {
                    introState
                } else {
                    folderList
                }

                Spacer(minLength: 0)

                footer
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Scan Dropbox")
                .font(Theme.Font.display(24, weight: .regular))
                .foregroundColor(Theme.Color.textStrong)
            Text(headerSubtitle)
                .font(Theme.Font.body(14))
                .foregroundColor(Theme.Color.textMuted)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var headerSubtitle: String {
        if dropboxService.scanInProgress {
            return "Scanning… \(dropboxService.lastScanFileCount) audio files, \(dropboxService.discoveredFolders.count) folders found"
        }
        if hasResults {
            return "\(dropboxService.lastScanFileCount) audio files, \(dropboxService.discoveredFolders.count) folders"
        }
        return "Find every folder that contains audio. Pick which to add as playlists."
    }

    private var introState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundColor(Theme.Color.textFaint)
            Text("Tap below to start. We'll stop after about 100 audio files; you can scan more later.")
                .font(Theme.Font.body(14))
                .foregroundColor(Theme.Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var folderList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(dropboxService.discoveredFolders) { folder in
                    discoveredRow(folder)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func discoveredRow(_ folder: DiscoveredFolder) -> some View {
        let isExisting = existingPaths.contains(folder.path)
        let isSelected = selected.contains(folder.path)

        return HStack(spacing: 14) {
            Image(systemName: isExisting ? "checkmark.circle.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
                .font(.system(size: 22, weight: .light))
                .foregroundColor(isExisting ? Theme.Color.textFaint : (isSelected ? Theme.Color.accent : Theme.Color.textFaint))

            VStack(alignment: .leading, spacing: 2) {
                Text(folder.displayName)
                    .font(Theme.Font.display(17, weight: .regular))
                    .foregroundColor(isExisting ? Theme.Color.textMuted : Theme.Color.textStrong)
                Text(folder.path)
                    .font(Theme.Font.label(11))
                    .foregroundColor(Theme.Color.textFaint)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text("\(folder.fileCount)")
                .font(Theme.Font.label(12))
                .foregroundColor(Theme.Color.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.Color.accentSoft)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Theme.Color.bgElev)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isExisting else { return }
            if selected.contains(folder.path) { selected.remove(folder.path) }
            else { selected.insert(folder.path) }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if dropboxService.scanInProgress {
                Button(action: { dropboxService.cancelScan() }) {
                    Text("Cancel scan")
                        .font(Theme.Font.label(14))
                        .foregroundColor(Theme.Color.text)
                }
            } else if !hasResults {
                Button(action: { dropboxService.startScan(limit: 100) }) {
                    Text("Scan Dropbox")
                        .font(Theme.Font.display(17, weight: .medium))
                        .foregroundColor(Theme.Color.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Theme.Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
            } else {
                if !selected.isEmpty {
                    Button(action: addSelected) {
                        Text("Add \(selected.count) playlist\(selected.count == 1 ? "" : "s")")
                            .font(Theme.Font.display(17, weight: .medium))
                            .foregroundColor(Theme.Color.bg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Theme.Color.accent)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    }
                }
                HStack(spacing: 14) {
                    if dropboxService.scanCanContinue {
                        Button(action: { dropboxService.continueScan(limit: 100) }) {
                            Text("Scan more")
                                .font(Theme.Font.label(14))
                                .foregroundColor(Theme.Color.accent)
                        }
                    } else {
                        Text("All audio scanned")
                            .font(Theme.Font.label(12))
                            .foregroundColor(Theme.Color.textFaint)
                    }
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(Theme.Font.label(14))
                        .foregroundColor(Theme.Color.text)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 12)
    }

    private func addSelected() {
        var nextOrder = (existingFolders.last?.sortOrder ?? -1) + 1
        for folder in dropboxService.discoveredFolders where selected.contains(folder.path) && !existingPaths.contains(folder.path) {
            modelContext.insert(StoryFolder(
                dropboxPath: folder.path,
                displayName: folder.displayName,
                sortOrder: nextOrder
            ))
            nextOrder += 1
        }
        do {
            try modelContext.save()
        } catch {
            print("[DiscoverFoldersSheet] save failed: \(error)")
        }
        dismiss()
    }
}
