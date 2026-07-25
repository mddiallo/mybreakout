# App Privacy ("Nutrition Label") Answers

Use these answers verbatim in App Store Connect → App Privacy. They match the machine-
readable declarations in `Prismabrique/PrivacyInfo.xcprivacy` and the behavior implemented
in `LocationOptInManager.swift`.

## Does this app collect data?

**Yes** — one data type, collected only if the player opts in.

## Data types collected

### Location → Coarse Location

- **Linked to the user's identity:** No
- **Used for tracking:** No
- **Purpose(s):** App Functionality (cosmetic ambient theme selection only)

No other data types (contact info, identifiers, usage data, diagnostics, purchases, etc.)
are collected by this app. Prismabrique has no analytics SDK, no crash reporter, no ad
network, and makes no network requests.

## Why "Coarse Location" and not "Precise Location"

The app requests When-In-Use authorization and immediately classifies a single location
fix into one of six broad regions (e.g. "Northern Skies", "Equatorial Glow") using latitude
bands roughly the width of a hemisphere. The precise coordinate is discarded in-memory
within the same function call that receives it (`LocationOptInManager.locationManager(_:didUpdateLocations:)`)
and is never written to disk, logged, or transmitted anywhere.

## Background location

Not used. `Info.plist` declares only `NSLocationWhenInUseUsageDescription`; there is no
`NSLocationAlwaysAndWhenInUseUsageDescription` key, no `UIBackgroundModes` location entry,
and the code never calls `requestAlwaysAuthorization()`, `allowsBackgroundLocationUpdates`,
or `startMonitoringSignificantLocationChanges()`.

## User controls

- The feature defaults to **off**.
- It is only ever activated after the player taps "Enable Ambient Theme" on the dedicated
  in-app consent screen (`LocationOptInSheetView`), which explains the above in plain
  language before any system permission prompt appears.
- It can be turned off at any time from Settings → "Use Approximate Location", which
  immediately stops any pending location request and clears the previously derived region
  from on-device storage.
- Declining or later revoking location permission in iOS Settings simply reverts the app to
  its default cosmetic theme; no gameplay feature depends on location.
