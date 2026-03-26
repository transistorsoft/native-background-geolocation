//
//  GeofenceEvent.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    public struct GeofenceEvent {
        public let identifier: String
        public let action: String
        public let timestamp: Date
        public let location: [String: Any]
        public let extras: [String: Any]?

        // Geofence center & radius (MEC for polygons)
        public let latitude: Double
        public let longitude: Double
        public let radius: Double
        public var center: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        // Trigger coordinate extracted from location dict
        public let triggerCoordinate: CLLocationCoordinate2D?
        public let triggerHeading: Double?

        public init(_ obj: TSGeofenceEvent) {
            self.identifier = obj.identifier
            self.action = obj.action
            self.timestamp = obj.timestamp
            self.location = obj.location as? [String: Any] ?? [:]
            self.extras = obj.extras as? [String: Any]

            self.latitude = obj.geofence.latitude
            self.longitude = obj.geofence.longitude
            self.radius = obj.geofence.radius

            let coords = self.location["coords"] as? [String: Any]
            if let lat = coords?["latitude"] as? Double,
               let lng = coords?["longitude"] as? Double {
                self.triggerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            } else {
                self.triggerCoordinate = nil
            }
            let heading = (coords?["heading"] as? NSNumber)?.doubleValue
            self.triggerHeading = (heading != nil && heading! >= 0) ? heading : nil
        }
    }
}
