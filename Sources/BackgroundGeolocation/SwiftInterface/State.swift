//
//  State.swift
//  TSLocationManager
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    /// Read-only snapshot of the SDK's current runtime state.
    ///
    /// Access via `BGGeo.shared.state`.
    ///
    /// ```swift
    /// let state = bgGeo.state
    /// if state.enabled && state.isMoving {
    ///     print("Tracking in motion, odometer: \(state.odometer)")
    /// }
    /// ```
    public struct State {
        /// Whether the SDK is currently tracking.
        public let enabled: Bool
        /// Whether the device is currently in motion.
        public let isMoving: Bool
        /// Current tracking mode: `.location` or `.geofence`.
        public let trackingMode: TrackingMode
        /// Distance travelled in meters since last `setOdometer` or `resetOdometer`.
        public let odometer: Double
        /// Estimated odometer error in meters.
        public let odometerError: Double
        /// Whether the scheduler is currently active.
        public let schedulerEnabled: Bool
        /// Whether the device rebooted since the SDK was last running.
        public let didDeviceReboot: Bool
        /// Whether the app was launched in the background by the OS.
        public let didLaunchInBackground: Bool
        /// `true` on the very first launch after the app is installed.
        public let isFirstBoot: Bool
    }
}
