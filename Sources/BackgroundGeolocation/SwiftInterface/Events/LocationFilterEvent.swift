//
//  LocationFilterEvent.swift
//  TSLocationManager
//
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import TSLocationManager

extension BGGeo {
    /// Delivered to ``BGGeo/onLocationFilter(_:)`` when the tracking location-filter
    /// rejects a raw location sample. Rejected locations are **not** delivered to
    /// ``BGGeo/onLocation(_:)``.
    public struct LocationFilterEvent {
        /// The rejected location (raw sample that failed the filter).
        public let location: LocationEvent
        /// Normalized reason the location was rejected, eg: `"low-accuracy"`.
        public let reason: String
        /// Horizontal accuracy (meters) of the rejected sample.
        public let accuracy: Double
        /// Configured tracking-accuracy threshold (meters) in effect at rejection.
        public let trackingAccuracyThreshold: Double

        public init(_ obj: TSLocationFilterEvent) {
            self.location = LocationEvent(obj.locationEvent)
            self.reason = obj.reason
            self.accuracy = obj.accuracy
            self.trackingAccuracyThreshold = obj.trackingAccuracyThreshold
        }
    }
}
