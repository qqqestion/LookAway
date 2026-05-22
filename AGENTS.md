# PROJECT KNOWLEDGE BASE

**Generated:** 2026-05-21
**Commit:** 440c0c2
**Branch:** master

## OVERVIEW

macOS menubar app enforcing the 20-20-20 eye health rule. Pure AppKit + Storyboard, Swift 5, zero dependencies.

## STRUCTURE

```
LookAway/
├── LookAway.xcodeproj/       # Xcode project (no SPM/CocoaPods)
├── LookAway/                  # All source — 4 Swift files, 306 lines
│   ├── AppDelegate.swift      # God object: timer, menu, window, notifications (244 lines)
│   ├── ViewController.swift   # Break overlay with Skip button (21 lines)
│   ├── WindowController.swift # Fullscreen overlay styling (14 lines)
│   ├── DockIcon.swift         # Dock icon visibility toggle (27 lines)
│   ├── Base.lproj/Main.storyboard
│   ├── Assets.xcassets/
│   ├── Info.plist
│   └── LookAway.entitlements
├── Artwork/                   # Sketch source + marketing PNGs
└── README.md                  # HTML-formatted (not Markdown)
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Timer logic | `AppDelegate.swift` ext "Timer" (L149-207) | 20s tick interval, `timeUntilBreak` countdown |
| Status bar menu | `AppDelegate.swift` L26-96 | Built in `applicationDidFinishLaunching` |
| Break overlay | `ViewController.swift` + `WindowController.swift` | Storyboard-loaded, fullscreen black 0.9 alpha |
| Skip/pause logic | `AppDelegate.swift` ext "Menu Items" (L212-237) | `pausedFor` in timer ticks |
| Dock visibility | `DockIcon.swift` | `NSApp.activationPolicy` switch |
| Window show/close | `AppDelegate.swift` L108-125 | Hides dock+menubar, sets window level |

## CODE MAP

| Symbol | Type | File | Role |
|--------|------|------|------|
| `AppDelegate` | class (NSApplicationDelegate) | AppDelegate.swift | Entry point (`@NSApplicationMain`), timer, menu, window lifecycle |
| `VCDelegate` | protocol | ViewController.swift | Delegate: ViewController → AppDelegate |
| `ViewController` | class (NSViewController) | ViewController.swift | Break overlay UI, skip button action |
| `WindowController` | class (NSWindowController) | WindowController.swift | Fullscreen overlay window config |
| `DockIcon` | struct | DockIcon.swift | Singleton, toggles dock icon via activationPolicy |

## CONVENTIONS

- **AppKit only** — no SwiftUI anywhere. UI in Interface Builder storyboard, outlets/actions via `@IBOutlet`/`@IBAction`
- **AppDelegate is the entire controller** — timer, menu, window, notifications all in one class via extensions
- **Timer-based** — `Timer.scheduledTimer` at 20s intervals, counter `timeUntilBreak` decrements per tick
- **Storyboard identifiers** — `WindowController` loaded by string ID `"WindowController"` (no compile-time safety)
- **Delegate pattern** — `VCDelegate` protocol for ViewController → AppDelegate communication
- **No access control** — all properties/methods implicitly `internal`
- **No tests, no CI, no linter** — zero test targets, zero CI workflows, zero linting configs

## ANTI-PATTERNS (THIS PROJECT)

- **DO NOT** add SwiftUI — entire codebase is AppKit + Storyboard
- **DO NOT** use `NSUserNotification` — deprecated since macOS 11, use `UNUserNotificationCenter`
- **DO NOT** force unwrap — `timer!.invalidate()`, `statusBarItem.menu!.items`, `as! Int` are crash risks; use `guard let` / optional chaining
- **DO NOT** ignore the entitlements typo — pbxproj references `LoolAway.entitlements` (double 'o'), file is `LookAway.entitlements`. Fix before any distribution signing.
- **DO NOT** trust `DockIcon.isVisible` setter — has a bug: reads old value instead of `newValue` (L13)

## KNOWN ISSUES

- `pbxproj`: entitlements path typo `LoolAway` → `LookAway` (lines 282, 302)
- `pbxproj`: hardcoded absolute path in workspace data (`/Users/samarjeet/...`)
- `pbxproj`: deployment target 10.10 vs README claims 10.14+
- `pbxproj`: product name `EyeRest` (original name, never updated)
- `AppDelegate.swift`: `NSUserNotification` deprecated API (L128-132)
- `AppDelegate.swift`: Timer retains target — retain cycle (benign for singleton AppDelegate)
- `DockIcon.swift`: setter uses `isVisible` instead of `newValue` (logic bug L13)
- `ViewController.swift`: `delegate` is IUO (`VCDelegate!`) — crash if accessed before set

## COMMANDS

```bash
# Build (CLI)
xcodebuild build -project LookAway.xcodeproj -scheme LookAway -configuration Release

# Open in Xcode
open LookAway.xcodeproj
```

## NOTES

- Bundle ID: `com.thelehhman.LookAway`, license: MIT
- App category: `public.app-category.healthcare-fitness`
- App Sandbox enabled with read-only user-selected files entitlement
- Remote: `git@github.com:qqqestion/LookAway.git` (fork of `thelehhman/LookAway`)
- Magic numbers scattered: `20` (timer interval), `60/20` (interval→minute conversion), `0.9` (overlay alpha)
