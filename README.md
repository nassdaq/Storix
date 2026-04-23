# Storix

Storage optimizer + cleaner for macOS. Radial sunburst + squarified treemap, AI-assisted classification, trash-safe deletion with undo.

## Stack

- macOS 14 Sonoma+, Swift 5.9, SwiftUI + AppKit bridges
- Swift Package Manager (6 modules) · Xcode project overlay via [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- AI: auto-detects `claude` CLI in `$PATH` / `$CLAUDE_BIN` / standard install locations; heuristics-only fallback
- Distribution: open source (MIT), ad-hoc-signed `.app` + `.dmg` via shell scripts; CI-built artifact via GitHub Actions

## Modules

| Module          | Role                                                                 |
| --------------- | -------------------------------------------------------------------- |
| `StorixCore`    | `StorageScanner`, hashers, `DuplicateFinder`, `PerceptualHasher`, 6 category detectors, models |
| `StorixCleaner` | Trash-safe deletion via `NSWorkspace.recycle` + JSON undo manifest   |
| `StorixAI`      | `ClaudeDetector`, `ClaudeClient` (shells out `claude -p`), NL → `QueryPredicate` |
| `StorixAgent`   | `MenuBarController`, `Scheduler` (LaunchAgent via `launchctl bootstrap`), `HeadlessRunner` |
| `StorixUI`      | Neon theme, `SunburstView` (tap-to-zoom), `TreemapView` (squarified), 7 screens |
| `Storix`        | SwiftUI `@main`; detects `--scheduled-scan` and runs headless        |

## Detectors (built-in)

| Detector                | Finds                                                      | Risk   |
| ----------------------- | ---------------------------------------------------------- | ------ |
| `DevCacheDetector`      | `node_modules`, `.venv`, `target`, `.gradle`, `.next`, etc. | low    |
| `SystemCacheDetector`   | `~/Library/Caches`, `Logs`, `WebKit`, `CrashReporter`      | low    |
| `XcodeJunkDetector`     | DerivedData, Archives, DeviceSupport, CoreSimulator caches | low    |
| `IncompleteDownloadDetector` | `.crdownload`, `.part`, `.download`, `.opdownload`   | low    |
| `LargeOldDetector`      | Files > 500 MB untouched > 180 days                        | high   |
| `DuplicateDetector`     | Byte-identical files (size → quick-hash → SHA-256 pipeline) | medium |
| `NearDuplicateDetector` | Perceptual dHash similarity (opt-in; heavy I/O)            | high   |

## Running

### Quick (dev iteration)

```bash
swift run Storix          # launches the bare Mach-O; MenuBarExtra/NSSavePanel stubs work
```

### Full `.app` bundle (recommended)

```bash
./Scripts/bundle-app.sh release    # → build/Storix.app (ad-hoc signed, entitled)
open build/Storix.app
```

On first launch, grant **Full Disk Access** in **System Settings → Privacy & Security → Full Disk Access** so the scanner can reach `~/Library`, `/System`, etc.

### Xcode workflow

```bash
brew install xcodegen        # one-time
xcodegen generate            # → Storix.xcodeproj
open Storix.xcodeproj
```

Xcode is required for SwiftUI previews, the LLDB debugger, and `Archive → Distribute App`. The generated project consumes the same SwiftPM package — no duplicated source lists.

### DMG release

```bash
./Scripts/bundle-dmg.sh 0.1.0      # → build/Storix-0.1.0.dmg
```

## Scheduled scans

Weekly scans are controlled from **Settings → Automation → Weekly background scan**. When enabled, Storix writes a LaunchAgent plist to `~/Library/LaunchAgents/galacha.industries.Storix.weekly.plist` and registers it via `launchctl bootstrap gui/$UID`. The agent invokes the app with `--scheduled-scan`, which runs headlessly (no UI), writes a summary JSON to `~/Library/Application Support/Storix/scheduled/`, and posts a `UNNotification` with the recoverable total.

## Design tokens

```
Background:  #0A0A0F
Surface:     #13131A
Text:        #F4F4F5
Accent:      #7C3AED → #3B82F6 → #06B6D4 → #10B981   (largest → smallest)
```

## Tests

```bash
swift test            # 21 tests across Scanner, Detectors, DuplicateFinder,
                      # PerceptualHash, QueryPredicate, NL strip helpers
```

## Requirements

- Xcode 15+ or Command Line Tools 15+
- macOS 14 Sonoma SDK or newer
- (Optional) [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) for natural-language queries

## Roadmap

- [x] Scanner engine with protected-path skipping
- [x] 6 detectors (5 heuristic + exact duplicates)
- [x] Trash + manifest + undo
- [x] Sunburst (tap-to-zoom) + squarified treemap
- [x] Claude CLI integration + NL query
- [x] Menu bar + LaunchAgent + headless mode
- [x] Share card export
- [ ] Near-duplicate opt-in UI flow
- [ ] Notarized + hardened-runtime signed releases
- [ ] Homebrew cask
