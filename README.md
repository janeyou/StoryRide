# StoryRide

Audio stories and songs from your Dropbox, with big synced word-by-word captions on screen. Built for toddlers who want their favorites in the car — read along while listening, glance at a giant play button, never fumble.

iOS 17+, SwiftUI, SwiftData.

## What it does

- Streams audio (m4a, mp3, wav, aac) from one or more Dropbox folders you configure.
- Plays with drive-safe chunky controls, lock-screen / AirPlay support, background audio.
- Shows huge synced captions while playing, via Dropbox's Riviera transcription API. Captions cache to disk keyed by content hash, so each file only transcribes once — even after rename, move, or reinstall.
- **Multi-folder playlists.** Swipe between them while driving.
- **One-tap "Scan Dropbox"** finds every folder that contains audio (capped at ~100 files per pass; "Scan more" continues from a cursor). Pick which to add as playlists.
- **Browse Dropbox** — tap through your folder tree to add a playlist manually, including folders that don't have audio yet.

## Setup

1. Clone the repo.

2. Get a Dropbox app key:
   - Go to https://www.dropbox.com/developers/apps → **Create app** → "Scoped access" → "Full Dropbox"
   - Permissions tab: enable `files.content.read` and `files.metadata.read`
   - Settings tab: copy the **App key** (short ~15-char string)

3. Configure secrets:
   ```bash
   cp Resources/Secrets.xcconfig.example Resources/Secrets.xcconfig
   ```
   Open `Resources/Secrets.xcconfig`, paste your app key after `DROPBOX_APP_KEY = `.

4. Open `StoryRide.xcodeproj` in Xcode 16+, run on iOS 17+ simulator or device.

5. On first launch, **Connect Dropbox** to OAuth in. Then either:
   - Tap **Scan Dropbox** to auto-discover audio folders, or
   - Tap **Add a folder** to browse and pick manually.

### Regenerating the Xcode project

The `.xcodeproj` is committed for convenience, but it's generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen). If you edit `project.yml`:

```bash
brew install xcodegen   # one-time
xcodegen generate
```

## Stack

- **UI / data:** SwiftUI, SwiftData, `@AppStorage` for prefs.
- **Audio:** `AVAudioPlayer`, `MPRemoteCommandCenter`, `MPNowPlayingInfoCenter`.
- **Dropbox:** SwiftyDropbox 10.x via SPM. Auth uses `setupWithAppKey`; access tokens auto-refresh.
- **Transcription:** Dropbox Riviera (`/2/files/get_transcript_async` + polling). Word-level timestamps.
- **Caption cache:** `Documents/Transcripts/{content_hash}.json`. Keyed by Dropbox's SHA-256 content hash, so the cache survives rename/move/re-upload.
- **Project file:** XcodeGen from `project.yml`.

## Structure

```
Models/         StoryFolder, StoryRecord, DropboxFile, TranscriptSegment
Services/       DropboxService (auth, list, scan, download), RivieraAPIClient,
                AudioPlayerService, CaptionSyncEngine
Views/          OnboardingView, LibraryView (pager), PlayerView, CaptionView,
                ControlsView, SettingsView (incl. DiscoverFoldersSheet +
                AddFolderSheet folder browser)
Utilities/      Theme (palette + type tokens), TranscriptStore, FileCache
Resources/      Info.plist, Assets.xcassets (coral play-icon), Secrets.xcconfig
```

## Design notes

Visual style follows [taste.md](https://github.com/janeyou/janeyoubradley.com/blob/main/taste.md): one accent at a time (coral here), generous breathing room, type does the work, no skeuomorphism. The toddler-friendly twist is SF Rounded at light/regular weights, bigger touch targets, and rounder play controls.

Caption highlighting: light → medium weight with a coral tint on the active word. No bold yellow.

## License

No license yet — assume all rights reserved until one is added.
