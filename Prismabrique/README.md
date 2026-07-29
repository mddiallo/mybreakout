# Prismabrique (iOS)

A native SwiftUI iPhone brick-breaker with 50 config-driven levels, built with **zero
external dependencies** (no SwiftPM packages, no CocoaPods, no SpriteKit — gameplay is
rendered with SwiftUI's `Canvas` API and driven by `TimelineView`).

This project lives alongside the original vanilla-JS web Breakout game at the repository
root; the web files are unrelated and unchanged.

## Requirements

- Xcode 16+ (Xcode "26" toolchain) on macOS, targeting **iOS 26.0+**
- No CocoaPods/SwiftPM/Carthage setup required — just open and build

## Opening the project

```bash
open Prismabrique.xcodeproj
```

Select the **Prismabrique** scheme and an iPhone simulator/device running iOS 26, then
Run (`⌘R`). Run tests with `⌘U` (uses the `PrismabriqueTests` target, hosted inside the
app).

Before publishing, update in the target's build settings (or in Xcode's Signing & 
Capabilities tab):
- `PRODUCT_BUNDLE_IDENTIFIER` (currently the placeholder `com.prismabrique.app`)
- Your Development Team for code signing
- Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` per release

## Project layout

```
Prismabrique.xcodeproj/         Xcode project (generated — see scripts/generate_xcodeproj.py)
Prismabrique/
├── PrismabriqueApp.swift       @main App entry point
├── PrivacyInfo.xcprivacy       Apple-required privacy manifest
├── Assets.xcassets/            App icon (single 1024×1024 universal icon) + accent color
├── Resources/
│   └── GameBalance.json        Single source of truth for every gameplay tuning value
├── Models/
│   ├── GameBalanceConfig.swift Codable mirror of GameBalance.json + loader
│   ├── LevelConfig.swift       Pure, deterministic 50-level generator
│   ├── BrickPattern.swift      Structural brick-layout templates + seeded RNG
│   ├── PlayerProgress.swift    Persisted progress/settings model
│   ├── HemisphereRegion.swift  Coarse location→region classification + ambient theme
│   └── AppState.swift          Root ObservableObject: navigation, progress, settings
├── Managers/
│   ├── AudioEngineManager.swift  Zero-asset tone-generation audio (AVAudioEngine)
│   ├── HapticsManager.swift      UIFeedbackGenerator wrapper
│   └── LocationOptInManager.swift Opt-in, When-In-Use-only CoreLocation wrapper
├── Game/
│   ├── GameEntities.swift      Runtime paddle/ball/brick/power-up state
│   └── GameEngine.swift        Physics, collisions, scoring, power-ups, win/lose
└── Views/                      SwiftUI screens (menu, level select, game, settings, …)

PrismabriqueTests/               XCTest unit tests (level generation, persistence, region
                                  classification, core engine sanity checks)
AppStoreMetadata/                Draft App Store listing copy + privacy nutrition label
PRIVACY.md                       User-facing privacy policy (host this at your privacy URL)
scripts/
├── generate_icon.py             Regenerates the app icon locally with Pillow
└── generate_xcodeproj.py        Regenerates project.pbxproj from the file system
```

## Config-driven design

Every gameplay-tunable number (paddle size/speed, ball speed curve, brick toughness,
power-up odds, scoring, lives, colors, audio tones, haptic styles, and the location
classification thresholds) lives in `Resources/GameBalance.json` and is loaded once at
startup by `GameConfigLoader`. `LevelGenerator` then derives all 50 levels purely as a
function of that config plus the level index — there is no per-level hardcoded array of
magic numbers to maintain, and regenerating the campaign is fully deterministic (see
`LevelGeneratorTests.testGenerationIsDeterministic`).

To change the difficulty curve, add levels, or retune balance, edit
`GameBalance.json` — no Swift code changes are required for most tuning.

## Optional location-based ambient theme

Prismabrique includes an optional, off-by-default feature that recolors the background to
match the player's broad hemisphere/region, using a single reduced-accuracy,
When-In-Use-only CoreLocation fix requested only after an explicit in-app opt-in. See
`PRIVACY.md` and `AppStoreMetadata/PrivacyNutritionLabel.md` for the full privacy design,
and `Managers/LocationOptInManager.swift` for the implementation and inline rationale.

## Regenerating generated assets

Because this environment has no macOS/Xcode available, the `.xcodeproj` and the app icon
were produced by small local scripts rather than authored by hand in Xcode's UI. If you add,
remove, or rename any source/resource file, re-run:

```bash
python3 scripts/generate_xcodeproj.py
```

If you change the color palette in `GameBalance.json` and want the icon to match:

```bash
pip install Pillow   # if not already installed
python3 scripts/generate_icon.py
```

Both scripts are idempotent and safe to re-run at any time.

## Known limitations / caveats

- **Not built or run in this environment.** There is no macOS/Xcode/iOS Simulator
  available here, so the project has been validated structurally (via the `xcodeproj`
  Ruby gem, which confirmed the pbxproj parses correctly, every referenced file resolves on
  disk, and target dependencies are wired) but has **not** been compiled or executed. Please
  open it in Xcode and build before relying on it.
- **No App Store screenshots** are included — capture these from Simulator/device per
  `AppStoreMetadata/Metadata.md`.
- **Placeholder bundle identifier, Development Team, and support/privacy URLs** must be
  updated before submitting to App Store Connect.
- **GameCenter/leaderboards, iCloud sync, and haptic-rich SpriteKit particle effects** were
  intentionally left out to keep the project dependency-free and scoped; they are
  reasonable candidates for a future iteration.
