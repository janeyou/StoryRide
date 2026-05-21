# Handoff: RideStory — Driving-Friendly Revamp

A redesign of the **StoryRide** iOS app (now renamed **RideStory** for the revamp) targeted at a real-world use case: a parent dropping a toddler off at school with the phone mounted on the dash. The redesign keeps the original app's Dropbox-backed audio + karaoke-caption engine but replaces the swipe-paginated playlist library with a one-glance home screen.

This handoff is for the existing SwiftUI codebase at **`janeyou/StoryRide`** (read alongside the SwiftUI source there).

---

## About the design files

The files in `prototype/` are **design references created in HTML/React**. They are *not* code to ship. They demonstrate intended layout, type, color, spacing, and interaction.

**Your task:** reimplement the screens in the existing SwiftUI app, reusing the project's current patterns — `@Model` SwiftData entities, `@EnvironmentObject DropboxService`, `AudioPlayerService`, `CaptionSyncEngine`, `RivieraAPIClient`, `Theme.swift`, etc. Do *not* add a JavaScript bundle to the iOS app. Translate the HTML/JSX into SwiftUI views.

---

## Fidelity

**High fidelity.** Colors, type sizes, spacing, corner radii, and interaction states are all final — recreate pixel-perfectly. Exception: the cover artwork in the prototype is a procedural SVG placeholder (linear gradient + a single motif) standing in for real cover images. Keep the procedural generator as a fallback when a story has no artwork.

---

## What changes vs. the existing app

The current `LibraryView.swift` wraps a horizontal `TabView(.page)` so each playlist becomes a full-page swipe view, with no way to see all playlists. The player auto-blasts giant karaoke captions and a 120px play button — fine for a parked toddler, hostile to a driver.

The revamp:

- **`HomeView`** (new) replaces `LibraryView` as the root post-onboarding screen. Surfaces continue-listening, favorites, all playlists, and recents on one scrollable screen.
- **`AllPlaylistsView`** (new) — full-screen browse of every playlist.
- **`PlaylistDetailView`** (new) — one playlist's stories with a "Play all" CTA and per-story play.
- **`PlayerView`** is refactored: captions are *hidden* by default, revealed by a CC pill. Cover art is the default surface.
- **`MiniPlayer`** (new) — persistent now-playing bar floating above content on every list/browse screen. Tap to expand into `PlayerView`.

Data model changes:

- Add `isStarred: Bool` and `lastPlayedAt: Date?` to `StoryRecord` (latter already exists).
- New SwiftData `@Model` for per-playlist listening state if you want to persist resume position per story.

---

## Screens / Views

### 1 · `HomeView` (replaces `LibraryView`)

**Purpose:** The driver opens the app at a red light, sees what they were last playing, and either taps to resume, taps a pinned favorite, or scans the playlist grid below.

**Layout** (top to bottom, all on a vertical `ScrollView`):

```
56pt safe-top padding
┌─────────────────────────────────────┐
│ "DRIVER MODE" eyebrow + ⚙ gear      │  Header strip, 18pt h-padding
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │  NOW PLAYING                  │  │
│  │  Goodnight Owl                │  │  Now-Playing tile
│  │  Bedtime Classics             │  │  220pt min height
│  │  ▭▭▭▭▭▭ progress             │  │  Gradient bg from playlist
│  │  3:24            -4:32        │  │  Transport row baked in
│  │   ⟲15    ▶/❚❚    15⟳          │  │
│  └───────────────────────────────┘  │
│                                     │
│  Favorites                          │  Section title (22pt top pad)
│  ┌───────────────────────────────┐  │
│  │ ◐ Goodnight Owl       ▶       │  │  Favorite row, 64pt min
│  ├───────────────────────────────┤  │
│  │ ◐ Pip the Penguin     ▶       │  │  3 visible, see-all elsewhere
│  ├───────────────────────────────┤  │
│  │ ◐ The Big Carrot      ▶       │  │
│  └───────────────────────────────┘  │
│                                     │
│  All playlists         See all →    │  Section title + action
│  ┌──────┐  ┌──────┐                 │  Grid (or list per user pref)
│  │ cov  │  │ cov  │  ...            │
│  │ Name │  │ Name │                 │
│  │ N stories                        │
│  └──────┘  └──────┘                 │
│                                     │
│  Recently played                    │
│  ◐ The Three Little Foxes  7:12 ▶   │
│  ◐ Moon Cake Night         5:48 ▶   │
│  ...                                │
│                                     │
│  (140pt bottom inset for MiniPlayer)│
└─────────────────────────────────────┘
                    ┌─────────────┐
                    │ MiniPlayer  │   Floating, 12pt insets,
                    │             │   44pt above home indicator
                    └─────────────┘
```

#### Header

- Padding: `50pt top, 18pt sides, 4pt bottom`
- Left cluster: car-glyph SVG (18×18) + label `"DRIVER MODE"` in accent color, `13pt SF Pro Rounded, weight: bold, letter-spacing: 1.3pt, uppercased`
- Right: gear icon button — 40×40pt, `chip` fill, `border: 1px rgba(255,255,255,0.07)`, corner radius 20pt (pill)

#### Now-Playing tile

- Outer: rounded rect, corner radius **28pt**, padding `20pt 20pt 22pt`
- Background: `linear-gradient(160deg, playlist.accentB, playlist.accentA 70%, #000 130%)`
- Box shadow: `0 16pt 36pt playlist.accentA @ 33%` (the gradient bottom color, soft glow)
- Min height: **220pt**
- Top row: `NOW PLAYING` eyebrow (`11pt, weight: bold, letter-spacing: 2pt, opacity: 0.85`) on the left, an opt-in CC pill on the right (`background: rgba(255,255,255,0.18), corner radius: 999, padding: 4pt 10pt, fontSize: 11pt`, weight bold, with CC glyph + "off")
- Title: story title — `30pt SF Pro Rounded, weight: bold, line-height: 1.08, letter-spacing: -0.5pt, marginTop: 16pt`
- Subtitle: playlist name — `15pt, opacity: 0.85, marginTop: 4pt`
- Progress bar: marginTop 18pt, height 4pt, corner radius 2pt, track `rgba(255,255,255,0.25)`, fill `white`
- Time labels: marginTop 6pt, `12pt, opacity 0.8`, elapsed left / `-remaining` right
- Transport row (marginTop 18pt):
  - Skip-back-15: **56×56pt** circle, `rgba(255,255,255,0.16)` fill, white glyph 26pt
  - Play/pause: **78×78pt** circle, `white` fill, `playlist.accentA` glyph 34pt, shadow `0 8pt 24pt rgba(0,0,0,0.25)`
  - Skip-fwd-15: mirror of skip-back

#### Favorites section

- Section title row: padding `22pt 22pt 10pt`, title "Favorites" at `18pt, weight: bold, letter-spacing: -0.2pt`. No action button.
- 3 rows in a `VStack(spacing: 8)`, padded `0 16pt`. Each row:
  - Min height **64pt**, padding `10pt 14pt 10pt 10pt`, corner radius **16pt**
  - Background `card` (`#15151a`), border `1px rgba(255,255,255,0.07)`
  - Left: 44×44pt cover (corner radius 10pt)
  - Middle (flex): title `17pt, weight: bold`, subtitle (playlist name) `12.5pt, color inkFaint, marginTop 2pt`
  - Right: 44×44pt play button — `rgba(255,255,255,0.06)` fill, `accent` glyph 18pt, corner radius 22pt

#### All playlists section

- Section title with right-aligned action button "See all →" in `accent`, `13pt, weight: bold`, tap opens `AllPlaylistsView`.
- Two layouts toggleable via user pref (currently default: **list**):

  **List** (default):
  - Vertical list, `0 16pt` h-padding
  - Each row: `12pt 6pt` padding, bottom hairline border `rgba(255,255,255,0.07)` (except last)
  - 56pt cover (corner radius 12pt), 14pt gap, title `16pt weight 600`, subtitle `13pt inkFaint marginTop 2pt`, trailing chevron

  **Grid**:
  - 2-column, gap 14pt, `0 16pt` h-padding
  - Tile: padding 12pt (or 10pt if not "big"), corner radius 16pt, `card` fill, 1px border
  - Cover fills tile width (corner radius 12pt), then 10pt marginTop title (`16pt weight 600`), 3pt marginTop subtitle

#### Recently played section

- Same row pattern as favorites, but minimal: 42pt cover (corner radius 9pt), 4 rows max, hairline divider between

#### MiniPlayer (floating)

- Position: absolute, `left: 12pt, right: 12pt, bottom: 44pt` (above home indicator)
- Size: full-width minus insets, height **64pt**
- Background: `rgba(20,18,16,0.92)`, backdrop blur 20pt + saturation 180%
- Border: 1px `rgba(255,255,255,0.07)`, corner radius **18pt**
- Shadow: `0 12pt 32pt rgba(0,0,0,0.55)`
- Content (h-stack, gap 12pt, padding `0 10pt`):
  - 48×48pt cover (corner radius 11pt)
  - Flex middle: title `15pt weight 600`, subtitle `12pt opacity 0.7 marginTop 1pt` showing `"{playlist} · {remaining} left"`, tiny 2pt progress bar marginTop 4pt
  - 44×44pt play button (accent fill, bg-color glyph)
- Tap the bar (anywhere but the play button) → opens `PlayerView`
- Tap play button → toggles `AudioPlayerService.togglePlayPause()` in place

---

### 2 · `AllPlaylistsView`

**Purpose:** The full library, browsable.

**Layout:**

- `DialTopBar` at the top: 44pt back button (chevron-left, `card` fill + border), then a 12pt gap, then the title block:
  - Eyebrow `"LIBRARY"` in accent color, `11pt weight 700, letter-spacing 1.6pt, uppercased`
  - Title `"All playlists"` — `22pt weight 700, line-height 1.15, letter-spacing -0.3pt`
- Trailing action: 44pt search button
- Below: stat-chip row (padding `14pt 16pt 4pt`, 8pt gap):
  - Accent chip: `"{N} playlists"` — `accent @ 13%` bg, `accent @ 27%` border, accent text
  - Neutral chips for `"{total} stories"` and `"A → Z"`: `card` bg, `border` border, `inkSoft` text
  - All chips: padding `7pt 12pt`, corner radius 999, `12.5pt weight 600`
- Content area (`12pt top, 16pt sides`): grid or list, identical to home's "All playlists" but for **all** playlists rather than first 6

MiniPlayer remains floating.

---

### 3 · `PlaylistDetailView`

**Purpose:** One playlist's stories, with a primary "Play all" CTA and per-row taps.

**Layout:**

- Background: solid `bg` (`#0a0a0c`), but with an **absolute gradient backdrop** (`0–360pt from top, linear-gradient 180deg, playlist.accentA @ 80% → playlist.accentA @ 33% → bg`) sitting behind the top of the content. This tints the header without affecting story rows.
- `DialTopBar`: back, eyebrow `"PLAYLIST"`, blank title text (the playlist name lives in the cover header below for hierarchy), trailing `…` (more) button in `rgba(255,255,255,0.10)` style.
- Cover header (`8pt 22pt 0`, centered):
  - **168pt square cover**, corner radius 20pt
  - 18pt marginTop, then playlist name — `28pt weight 700, line-height 1.1, letter-spacing -0.4pt`
  - 4pt marginTop, meta: `"{count} stories · {N} min total"` — `13.5pt, rgba(255,255,255,0.7)`
- Action row (`18pt 22pt 0`, 10pt gap):
  - **Primary "Play all" button**: flex 1, height **56pt**, corner radius **28pt** (pill), `accent` fill, `bg` text — `17pt weight 700`, h-stack with play glyph (20pt) + label, shadow `0 8pt 24pt accent @ 33%`
  - **Shuffle/dice button**: 56×56pt circle, `card` fill, 1px border, `ink` glyph (custom shuffle SVG)
  - **Star/favorite button**: 56×56pt circle, `card` fill, 1px border, `accent` glyph
- Story list (`22pt 16pt 0`, vstack gap 6pt):
  - Each row: minHeight **64pt**, padding `12pt 10pt 12pt 14pt`, corner radius **16pt**, `card` fill, 1px border
  - Leading 28pt column with the row number (`13pt weight 600, color inkSoft`), or a checkmark glyph (18pt, accent, weight 2.3 stroke) if `listened >= 1`
  - 14pt gap, then title `16pt weight 600, color ink` (or `inkFaint` if completed), single-line with ellipsis
  - Below title: meta row at `12.5pt, color inkFaint, gap 6pt`: duration, then if in progress, `· {pct}% in` in accent; if starred, a filled-star glyph (12pt) in accent
  - Trailing 44×44pt play button — corner radius 22pt. If row is in progress: `accent` fill + `bg` glyph. Otherwise: `rgba(255,255,255,0.06)` fill + `accent` glyph

MiniPlayer remains floating.

---

### 4 · `PlayerView` (refactored)

**Purpose:** Full-screen playback. **Captions hidden by default.**

**Layout** (no nav bar; close button is part of the chrome):

- Top chrome (`54pt 16pt 0`, h-stack space-between):
  - 40pt chevron-down close button — `rgba(255,255,255,0.08)` fill, 1px `rgba(255,255,255,0.10)` border, corner radius 20pt
  - Centered text block (eyebrow `"PLAYING FROM"` at 11pt weight 700, opacity 0.7, letter-spacing 1.6pt; then playlist name at 14pt weight 600)
  - 40pt more (`…`) button matching the close
- Backdrop wash: same gradient idea as `PlaylistDetailView`, `linear-gradient 180deg, playlist.accentA @ 80% → 33% → transparent` over the top 60% of the screen.
- Surface area (`24pt 28pt 0`): **either** the cover (`100% width up to 320pt`, corner radius 24pt) **or** the `CaptionPanel` — see CC pill below
  - When showing cover: a faint 40pt star button overlay at `top: 14pt, right: 14pt` — `rgba(0,0,0,0.35)` w/ blur, 1px `rgba(255,255,255,0.18)` border, accent glyph
- Title block (`22pt 28pt 0`): story title `26pt weight 700, line-height 1.1, letter-spacing -0.4pt`; subtitle `14pt opacity 0.7 marginTop 4pt` showing `"narrated · {min} min"`
- Progress (`24pt 28pt 0`): track `rgba(255,255,255,0.15)` height 4pt, fill `accent`; elapsed/remaining labels at `12pt opacity 0.7 marginTop 7pt`
- Transport (`20pt 28pt 0`, h-stack space-between):
  - Skip-back-15: **60×60pt** circle, `rgba(255,255,255,0.08)` fill, `ink` glyph 28pt
  - Play/pause: **80×80pt** circle, `accent` fill, `bg` glyph 34pt, shadow `0 8pt 24pt accent @ 33%`
  - Skip-fwd-15: mirror of skip-back
- **CC pill** (marginTop 24pt, centered): an `inline-flex` pill, padding `10pt 16pt`, corner radius 999. Toggles caption panel.
  - When off: `rgba(255,255,255,0.08)` fill, `ink` text, label `"Show read-along"`
  - When on: `accent` fill, `bg` text, label `"Hide read-along"`
  - Always shows the CC glyph (18pt) on the left

#### CaptionPanel (revealed inside the surface area)

- Same dimensions as cover (`width 100% up to 320pt, aspect 1:1`), corner radius 24pt
- Background `rgba(0,0,0,0.45)`, 1px `rgba(255,255,255,0.10)` border, backdrop blur 20pt + saturation 180%
- Padding 24pt, contents centered
- Rendered caption words from `CaptionSyncEngine.visibleWords` flow-laid (existing `FlowLayout` in `CaptionView.swift` is fine to reuse):
  - Active word: `accent` color, `weight 700`
  - Inactive: `rgba(255,255,255,0.88)`, `weight 400`
  - Font size: user-configurable, default 36pt (was 48pt in the original — the smaller default is intentional now that captions are opt-in and the panel is the secondary surface)

---

## Interactions & behavior

- **Tap continue tile on Home** → opens `PlayerView` for current story
- **Tap any cover anywhere** → if a playlist tile: opens `PlaylistDetailView`; if a story row: opens `PlayerView` and starts the story
- **Tap MiniPlayer body** → opens `PlayerView`
- **Tap MiniPlayer play button** → toggles playback in place, mini stays visible
- **CC pill** → cross-fade swap of cover ↔ caption panel (0.2s ease)
- **"See all →"** on Home → push `AllPlaylistsView`
- **Back chevron in detail views** → pop
- **Skip 15** uses existing `AudioPlayerService.skipBackward / skipForward`
- **Play all** in playlist detail → enqueue all stories, play first
- **Shuffle** in playlist detail → enqueue all in random order, play first (extend `AudioPlayerService` with a queue if not present)
- **Star button** in `PlayerView` / playlist detail → toggle `StoryRecord.isStarred` (new field) and persist; the surfaced "Favorites" section is `StoryRecord` where `isStarred == true`, ordered by `lastPlayedAt`

---

## State management (SwiftUI mapping)

| Prototype concept            | SwiftUI implementation                                              |
| ---                          | ---                                                                 |
| `RS_PLAYLISTS`               | Existing `@Query StoryFolder` + a new computed `count` from Dropbox |
| `RS_CONTINUE`                | New `@AppStorage("lastPlayedStoryId")` + look up `StoryRecord`      |
| `RS_FAVORITES`               | `@Query(filter: #Predicate { $0.isStarred }) [StoryRecord]`         |
| `RS_RECENT`                  | `@Query(sort: \.lastPlayedAt, order: .reverse)` limit 5             |
| `rsStoriesFor(playlistId)`   | `DropboxService.files(in: folder.dropboxPath)`                      |
| `s.listened` (0..1)          | New `StoryRecord.lastPosition: TimeInterval` ÷ `duration`           |
| Tweaks panel (in prototype)  | Settings screen in real app: layout (grid/list), accent, caption size, "show captions by default" |

The prototype's "Tweaks" panel is a design-time control, not part of the shipping app. The values it exposes (layout, accent, captions-default, caption size) map to real settings in `SettingsView.swift`. Default values picked by the designer:

- Layout: **list**
- Accent: **`#ffd166`** (warm yellow, was coral `#e09b87` in original)
- Captions default: **off** (was always on)
- Caption font size: **36pt** (was 48pt)
- MiniPlayer: **enabled**

---

## Design tokens

Update `Utilities/Theme.swift` with these. The `Theme.Color` namespace already exists — extend it.

### Colors (dark palette — primary)

```swift
extension Theme.Color {
    // Surfaces
    static let bg        = Color(hex: 0x0a0a0c)          // page background
    static let card      = Color(hex: 0x15151a)          // raised card surface
    static let cardElev  = Color(hex: 0x1c1c22)          // hover/active raise
    static let chip      = Color(hex: 0x1f1f25)          // pill / chip surface
    static let border    = Color.white.opacity(0.07)     // 1px hairline

    // Ink
    static let ink       = Color(hex: 0xf5f1ea)          // primary text
    static let inkSoft   = Color(hex: 0xcfc7b8)          // secondary
    static let inkFaint  = Color(hex: 0x8a8270)          // tertiary

    // Accent (user-configurable in Settings, default warm yellow)
    static let accent    = Color(hex: 0xffd166)
    static let accentFg  = bg                            // text on accent
}
```

User-selectable accent palette (Settings → Color):

| Hex        | Use                                  |
| ---        | ---                                  |
| `#e09b87`  | Coral (original brand)               |
| `#f5a25a`  | Sunset                               |
| `#7ec4a0`  | Mint                                 |
| `#9a8cd1`  | Lilac                                |
| `#e07b7b`  | Berry                                |
| `#ffd166`  | **Honey (default)**                  |

### Playlist gradient palette

Each playlist has a deterministic two-color gradient + a motif token. Keep the mapping below for backfill if a folder has no artwork:

```swift
struct PlaylistVisual {
    let accentA: Color   // dark stop
    let accentB: Color   // light stop
    let motif: Motif     // .moon / .sun / .leaf / .wave / .rings / .arc
}
```

| Playlist seed name       | accentA   | accentB   | motif  |
| ---                      | ---       | ---       | ---    |
| "Bedtime"                | `#1f2a55` | `#3a4d96` | moon   |
| "Mornings"               | `#c25a2d` | `#f3a35a` | sun    |
| "Animal"                 | `#1f5238` | `#3f8c5b` | leaf   |
| "Lullaby"                | `#3a2456` | `#7e5da6` | wave   |
| "Imagination/Made-up"    | `#7a2549` | `#c46d8a` | rings  |
| "Adventure"              | `#1f4a59` | `#4a8aa3` | arc    |
| "Garden/Nature"          | `#3d5a1f` | `#7ea24b` | leaf   |
| "Friends/Feelings"       | `#7a5a1c` | `#d4a44a` | sun    |

Generate via a simple keyword match on the folder display name, or by a stable hash of the path if no match.

### Typography

System rounded throughout. SwiftUI: `.system(size:, weight:, design: .rounded)`. The prototype uses these sizes — translate 1:1 to pt:

| Role                              | Size | Weight   | Notes                        |
| ---                               | ---  | ---      | ---                          |
| Page title (e.g. "All playlists") | 22   | bold     | letter-spacing -0.3, line-height 1.15 |
| Story/now-playing title (large)   | 30   | bold     | letter-spacing -0.5, line-height 1.08 |
| Story title (player)              | 26   | bold     | letter-spacing -0.4, line-height 1.10 |
| Playlist name (detail header)     | 28   | bold     | letter-spacing -0.4, line-height 1.10 |
| Section title ("Favorites" etc.)  | 18   | bold     | letter-spacing -0.2           |
| Row title (favorites/list)        | 17   | semibold |                              |
| Tile title (grid)                 | 16   | semibold |                              |
| Body / list title                 | 16   | semibold |                              |
| Subtitle / meta                   | 13.5–14 | regular | opacity 0.7 on dark        |
| Microcopy                         | 12.5 | semibold | color `inkFaint`             |
| Eyebrows ("NOW PLAYING")          | 11   | bold     | uppercased, letter-spacing 1.6–2.0 |
| Tab labels / button copy          | 17   | semibold | inside accent buttons        |

### Spacing scale

Multiples of 2 with a strong preference for 4/8/12/16/22 in section padding. Use 22pt for section title vertical rhythm.

### Corner radii

| Element                | Radius |
| ---                    | ---    |
| Now-playing tile       | 28pt   |
| Player cover / caption | 24pt   |
| Playlist detail cover  | 20pt   |
| Card / tile            | 16pt   |
| MiniPlayer             | 18pt   |
| Favorite row           | 16pt   |
| Story row              | 16pt   |
| Cover thumbnail (44–60)| 9–12pt |
| Pills / chips          | 999 (fully round) |
| Circular buttons       | half their size |

### Shadows

| Element                  | Shadow                                          |
| ---                      | ---                                             |
| MiniPlayer               | `0 12pt 32pt rgba(0,0,0,0.55)`                  |
| Now-playing tile         | `0 16pt 36pt {playlist.accentA}@33%`            |
| Primary action button    | `0 8pt 24pt {accent}@33%`                       |
| Player play button       | `0 8pt 24pt {accent}@33%`                       |
| Now-playing play button  | `0 8pt 24pt rgba(0,0,0,0.25)`                   |

### Tap targets

Driving means **bigger**. Floors:
- Any primary control: **44pt**
- Now-playing skip buttons: **56pt**
- Now-playing play button: **78pt**
- Player skip buttons: **60pt**
- Player play button: **80pt**
- Primary action buttons (Play all etc.): **56pt** height

---

## Assets

No bitmap assets in this handoff. Everything is procedural:

- **Icons:** redraw using SF Symbols where possible — `play.fill`, `pause.fill`, `gobackward.15`, `goforward.15`, `star` / `star.fill`, `magnifyingglass`, `gear`, `ellipsis`, `chevron.down`, `chevron.right`, `captions.bubble`, `car.fill`, `shuffle`. The HTML prototype draws them inline because it has no SF Symbols.
- **Cover artwork:** the prototype renders a `<linearGradient>` + a single motif (moon, sun, leaf, wave, rings, arc) as SVG. In SwiftUI, render the gradient with `LinearGradient` and the motif with `Path` / `Circle` / `Capsule` in a `ZStack`. Use the procedural cover whenever a story has no explicit artwork.

---

## Files in this bundle

```
prototype/
  index.html         # Entry point — open in a browser to see the prototype
  app.jsx            # Design canvas + tweaks panel wiring + variation registry
  data.jsx           # All sample data (playlists, stories, recents, favorites,
                     #   captions) + icon set + procedural cover renderer
  variations.jsx     # Three home variations: HomeWarm (A), HomeDark (B),
                     #   HomeDial (C) + MiniPlayer + PlaylistGrid helper
  player.jsx         # Shared full-screen Player + CaptionPanel
  dial-screens.jsx   # C-specific: AllPlaylistsDial + PlaylistDetailDial
  ios-frame.jsx      # iPhone device chrome (status bar, home indicator)
  design-canvas.jsx  # Pan/zoom canvas wrapper (Figma-ish)
  tweaks-panel.jsx   # Floating tweaks panel
```

To run the prototype locally: open `prototype/index.html` in a modern browser. No build step. Tap any artboard's expand icon (top-right when hovered) to take it full-screen and click through the flow.

The **C variant** (top section of the canvas) is the approved direction. **A** and **B** in the lower section are reference-only alternatives that were rejected.

---

## Open questions for the developer

1. **Queue model.** The original `AudioPlayerService` plays one URL at a time. The "Play all" action and continuous-play between recently-played stories assume a queue. Extend or wrap with a queue manager — recommend `[StoryRecord]` array + index, with `next()/previous()` and `enqueue(playlist:)`.
2. **Resume position per story.** Currently only the *current* track's position is tracked in `AudioPlayerService`. To make the home "Continue" tile work, persist `lastPosition: TimeInterval` on `StoryRecord` and write it on pause/background.
3. **Mini player visibility logic.** Show iff `AudioPlayerService.hasLoadedTrack`; hide on `PlayerView` itself (would double up).
4. **Driver-mode toggle.** The prototype assumes the app is always in driver mode. Consider an explicit toggle in Settings that, when off, allows showing captions by default and a smaller play button (parked mode).
