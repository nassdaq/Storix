# Storix

Storage optimizer + cleaner for macOS. Radial sunburst treemap, AI-assisted classification, trash-safe deletion with undo.

## Status

Scaffold only. No business logic implemented yet — every module compiles with typed stubs marked `// MARK: TODO`.

## Stack

- **Platform:** macOS 14 Sonoma+, Swift 5.9, SwiftUI, AppKit where needed
- **Build:** Swift Package Manager (library modules) + Xcode project overlay for .app bundle
- **AI:** Auto-detects `claude` CLI in `$PATH` (Claude Code) and shells out. No CLI → heuristics only.
- **Distribution:** Open source (MIT)

## Modules

| Module          | Role                                                             |
| --------------- | ---------------------------------------------------------------- |
| `StorixCore`    | Scanner, hasher, duplicate finder, category detectors, models    |
| `StorixCleaner` | Trash-safe deletion via `NSWorkspace.recycle` + JSON undo manifest |
| `StorixAI`      | `claude` CLI detection + natural-language query parser           |
| `StorixAgent`   | Menu bar status item + LaunchAgent scheduler (weekly scans)      |
| `StorixUI`      | Theme, sunburst/treemap views, screens                           |
| `Storix` (exe)  | SwiftUI `@main` entry wiring all modules                         |

## Features (v1 scope)

- Full disk scan (Full Disk Access entitlement required)
- Categories: dev caches, duplicates (exact + perceptual), system/app caches, large + old files
- Radial sunburst treemap (Storix neon palette)
- Natural-language query ("find videos from 2022 over 1GB") when `claude` CLI present
- Menu bar live disk-use indicator
- Scheduled weekly scan via LaunchAgent
- Before/after share card
- Deletion via Trash + JSON manifest; one-click undo of last N cleanups

## Design tokens

```
Background:  #0A0A0F
Text:        #F4F4F5
Accent:      #7C3AED  (largest slices)
Ring:        #3B82F6 → #06B6D4 → #10B981 (smallest slices)
```

## Build

```bash
swift build              # compile all modules
swift test               # run StorixCoreTests
swift run Storix         # launch (dev only — no .app bundle)
```

For production `.app` bundle with Full Disk Access entitlement, use the `Scripts/bundle-app.sh` helper (TODO) or open the package in Xcode and configure a proper app target.

## Requirements

- Xcode 15+
- macOS 14 Sonoma+ SDK

## Entitlements

See `App/Storix.entitlements`. Grant Full Disk Access via **System Settings → Privacy & Security → Full Disk Access** after first launch.

## Roadmap

- [ ] Phase 1 — scanner engine (rayon-style parallel walk, FileManager enumerator)
- [ ] Phase 2 — duplicate detection (SHA256 exact + pHash perceptual)
- [ ] Phase 3 — sunburst renderer (Canvas or Metal)
- [ ] Phase 4 — Claude CLI integration
- [ ] Phase 5 — menu bar + LaunchAgent
- [ ] Phase 6 — notarization + signed DMG release
