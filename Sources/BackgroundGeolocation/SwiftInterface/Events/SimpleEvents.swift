//
//  SimpleEvents.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import TSLocationManager

extension BGGeo {
    public struct ScheduleEvent {
        /// The full plugin state dictionary at the time the schedule fired.
        public let state: [String: Any]

        /// Whether this is a scheduled **ON** (`true`) or **OFF** (`false`) event.
        public var enabled: Bool { state["enabled"] as? Bool ?? false }

        /// The tracking mode for this schedule slot: `.location` or `.geofence`.
        public var trackingMode: BGGeo.TrackingMode {
            guard let raw = state["trackingMode"] as? Int else { return .location }
            return BGGeo.TrackingMode(rawValue: raw) ?? .location
        }

        public init(_ obj: TSScheduleEvent) {
            self.state = obj.state as? [String: Any] ?? [:]
        }
    }

    public struct GeofencesChangeEvent {
        public let on: [BGGeo.Geofence]
        public let off: [String]

        public init(_ obj: TSGeofencesChangeEvent) {
            self.on = (obj.on as? [TSGeofence] ?? []).map { BGGeo.Geofence($0) }
            self.off = obj.off.compactMap { $0 as? String }
        }
    }

    public struct PowerSaveChangeEvent: Sendable {
        public let isPowerSaveMode: Bool

        public init(_ obj: TSPowerSaveChangeEvent) {
            self.isPowerSaveMode = obj.isPowerSaveMode
        }
    }

    public struct ConnectivityChangeEvent: Sendable {
        public let hasConnection: Bool

        public init(_ obj: TSConnectivityChangeEvent) {
            self.hasConnection = obj.hasConnection
        }
    }

    public struct EnabledChangeEvent: Sendable {
        public let enabled: Bool

        public init(_ obj: TSEnabledChangeEvent) {
            self.enabled = obj.enabled
        }
    }
}
