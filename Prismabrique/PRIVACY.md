# Prismabrique Privacy Policy

_Last updated: 2026-07-25_

Prismabrique is designed to work great with no personal data collection at all. This
document explains the one optional feature that touches location data, and confirms
everything else the app does and does not do.

## Summary

- Prismabrique does not require an account, does not show ads, and does not include any
  third-party analytics, advertising, or tracking SDKs.
- Prismabrique makes no network requests. All gameplay, progress, and settings are stored
  only on your device.
- The only sensitive permission Prismabrique can ever request is **location**, and only for
  a single optional cosmetic feature described below. It is off by default.

## Optional feature: Ambient Region Theme

Prismabrique can recolor its background ambience to broadly match where you are in the
world (for example, cooler blues for northern latitudes, warmer tones near the equator).

This feature:

- Is **off by default** and only turns on if you explicitly tap "Enable Ambient Theme" in
  Settings, after reading an in-app explanation screen.
- Requests **"When-In-Use"** location authorization only. Prismabrique never requests
  "Always" authorization and never runs any location code in the background.
- Requests a single, **reduced-accuracy** location fix (not continuous or precise GPS
  tracking) each time you enable it or resume with it enabled.
- Converts that fix into a **broad region label** (e.g. "Northern Skies", "Equatorial
  Glow") on your device immediately, and **discards the exact coordinates** — only the
  broad label is ever stored, never latitude/longitude.
- Never sends any location data anywhere; there is no server component to this app.
- Can be turned off at any time in Settings, which immediately stops using location and
  deletes the stored region label from your device.
- Has **zero effect on gameplay** — it is purely cosmetic. You can enjoy the full 50-level
  game, with all mechanics and difficulty intact, without ever enabling it.

Declining the system location permission prompt, or disabling Location Services for
Prismabrique in iOS Settings, simply keeps the app on its default color theme — nothing
else changes.

## Data Prismabrique stores on your device

- Game progress: highest unlocked level, per-level stars/best scores, total score.
- Settings: sound, haptics, reduce motion, high contrast, and whether the ambient region
  theme is enabled.
- If the ambient region theme is enabled: a single text label describing your broad region
  (never coordinates).

All of the above is stored locally via `UserDefaults` and can be erased at any time using
the "Reset Progress" button in Settings, which also disables and clears the location-based
theme.

## Children's privacy

Prismabrique does not knowingly collect personal information from anyone, including
children. The optional location feature requires an explicit, deliberate opt-in action and
is not enabled automatically for any user.

## Contact

Questions about this policy can be sent to the support address listed on the app's App
Store page. (Replace this placeholder with a real contact address before publishing.)
