import Foundation
import CoreLocation
import Combine

/// Manages the fully optional "ambient theme by region" feature.
///
/// Privacy design (see `PRIVACY.md` for the user-facing explanation):
/// - The feature is **off by default** and only starts after the player explicitly taps
///   "Enable" on `LocationOptInSheetView` — authorization is never requested at launch.
/// - Only **When-In-Use** authorization is requested; this app never requests, and its
///   Info.plist never declares, "Always" / background location usage.
/// - A single one-shot, **reduced-accuracy** fix is requested (`requestLocation`, not
///   continuous updates), which is immediately converted to a coarse `HemisphereRegion`
///   and then discarded — raw latitude/longitude values are never written to disk.
/// - The player can disable the feature at any time from Settings, which stops any pending
///   request and clears the previously stored region classification.
@MainActor
final class LocationOptInManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentRegion: HemisphereRegion?
    @Published private(set) var isResolving = false
    @Published private(set) var lastError: String?

    private let manager = CLLocationManager()
    private let config: GameBalanceConfig

    /// Invoked whenever a new coarse region has been derived, so `AppState` can persist
    /// just the enum value (never raw coordinates) into `PlayerProgress`.
    var onRegionResolved: ((HemisphereRegion) -> Void)?

    init(config: GameBalanceConfig = GameConfigLoader.shared, storedRegion: HemisphereRegion?) {
        self.config = config
        self.authorizationStatus = CLLocationManager().authorizationStatus
        self.currentRegion = storedRegion
        super.init()
        manager.delegate = self
        // Reduced accuracy is a deliberate, hardcoded privacy invariant (not read from
        // `config.location.desiredAccuracy`, which exists only for documentation/testing
        // purposes) -- this app must never request higher-than-reduced accuracy regardless
        // of any tuning file, since the feature only ever needs a coarse region.
        manager.desiredAccuracy = kCLLocationAccuracyReduced
        manager.distanceFilter = config.location.distanceFilterMeters
    }

    /// Call only from an explicit user action (e.g. tapping "Enable" in the opt-in sheet).
    /// Never invoked automatically during app startup.
    func requestOptIn() {
        lastError = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            resolveRegionOnce()
        case .denied, .restricted:
            lastError = "Location access is denied in iOS Settings. You can still play with the classic theme."
        @unknown default:
            break
        }
    }

    /// Disables the feature immediately: stops any in-flight request and forgets the
    /// derived region so the UI reverts to the classic theme. Does not attempt to revoke
    /// OS-level authorization (that remains the user's choice in iOS Settings) but the app
    /// will simply stop requesting or using location from this point on.
    func disable() {
        manager.stopUpdatingLocation()
        isResolving = false
        currentRegion = nil
    }

    private func resolveRegionOnce() {
        guard CLLocationManager.locationServicesEnabled() else {
            lastError = "Location Services are off for this device."
            return
        }
        isResolving = true
        manager.requestLocation()
    }
}

extension LocationOptInManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.resolveRegionOnce()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let latitude = location.coordinate.latitude
        Task { @MainActor in
            // Immediately reduce to a coarse region; the CLLocation itself is discarded
            // once this function returns and is never persisted.
            let region = HemisphereRegion.classify(latitude: latitude, config: self.config)
            self.currentRegion = region
            self.isResolving = false
            manager.stopUpdatingLocation()
            self.onRegionResolved?(region)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isResolving = false
            self.lastError = "Couldn't determine an approximate location right now."
        }
    }
}
