# Prismabrique — App Store Metadata

Draft listing copy and submission notes. Replace bracketed placeholders before submitting
in App Store Connect.

## App Information

- **Name:** Prismabrique
- **Subtitle:** Neon Brick-Breaking Arcade
- **Primary category:** Games → Arcade
- **Secondary category:** Games → Puzzle
- **Age rating:** 4+ (no objectionable content; mild flashing neon visuals — verify against
  Apple's photosensitivity guidance if strobing effects are added later)
- **Bundle identifier:** `com.prismabrique.app` (placeholder — replace with your registered
  App ID before archiving)
- **Version:** 1.0.0 (`MARKETING_VERSION`), build 1 (`CURRENT_PROJECT_VERSION`)
- **Supported devices:** iPhone only (`TARGETED_DEVICE_FAMILY = 1`)
- **Minimum iOS version:** 26.0

## Promotional Text (170 chars)

> 50 hand-tuned levels of neon brick-breaking action. Swipe to move, tap to launch, chase
> combos and power-ups, and light up every brick in sight.

## Description

Prismabrique is a fast, focused arcade brick-breaker built entirely with native SwiftUI —
no ads, no accounts, no tracking. Break through 50 progressively harder levels, each with a
unique brick layout, tuned ball speed, and power-up mix. Catch Wide Paddle, Slow Ball,
Multi-Ball, Magnet, Shield, and Extra Life drops to chain bigger combos and rescue tricky
runs.

Highlights:
- 50 levels with genuinely progressive difficulty — speed, brick toughness, and layout
  complexity all scale smoothly from level 1 to level 50.
- Simple touch controls: drag to steer the paddle, tap to launch the ball.
- Score, lives, stars, and level progress are saved automatically on your device.
- Sound, haptics, reduced motion, and a high-contrast mode are all available in Settings.
- Optional ambient region theme: with your explicit permission, Prismabrique can recolor
  its background to match your broad hemisphere/region. This is entirely cosmetic, fully
  optional, off by default, and never uses your exact location or background tracking —
  see the in-app Privacy Details screen for the full explanation.
- No third-party SDKs, no analytics, no ads, and no account required to play.

## Keywords

`breakout, brick breaker, arcade, retro, neon, paddle, ball, puzzle, classic arcade`

## Support URL / Marketing URL

`https://example.com/prismabrique/support` (placeholder — update with your real URL)

## Privacy Policy URL

`https://example.com/prismabrique/privacy` (placeholder). Host the contents of
`../PRIVACY.md` at this URL before submitting — it is required by App Store Connect and is
also referenced by the in-app "Privacy Details" screen wording.

## App Privacy ("Nutrition Label") Questionnaire Answers

See `PrivacyNutritionLabel.md` for the exact answers to use in App Store Connect's
"App Privacy" section, matching `Prismabrique/PrivacyInfo.xcprivacy`.

## Screenshots & Preview

No device screenshots are included in this repository (generating pixel-accurate,
device-framed marketing screenshots requires running the app in Xcode/Simulator on macOS,
which is unavailable in this environment). Before submission, capture screenshots for at
least one required device size (e.g. 6.7" and 5.5" iPhone) directly from Simulator or a
physical device running the Main Menu, Level Select, and in-game HUD screens.

## What's New (Version 1.0.0)

> Initial release: 50 levels, touch controls, combos, six power-up types, save progress,
> accessibility settings, and an optional location-based ambient theme.
