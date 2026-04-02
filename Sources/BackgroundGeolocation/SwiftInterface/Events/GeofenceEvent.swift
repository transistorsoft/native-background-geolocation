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
        public let location: BGGeo.LocationEvent
        public let geofence: BGGeo.Geofence
        public let extras: [String: Any]?

        // Trigger coordinate extracted from location coords
        public let triggerCoordinate: CLLocationCoordinate2D?
        public let triggerHeading: Double?

        public init(_ obj: TSGeofenceEvent) {
            self.identifier = obj.identifier
            self.action = obj.action
            self.timestamp = obj.timestamp
            let locationDict = obj.location as? [String: Any] ?? [:]
            let coordsDict = locationDict["coords"] as? [String: Any]
            let clLocation = CLLocation(
                latitude: (coordsDict?["latitude"] as? NSNumber)?.doubleValue ?? 0,
                longitude: (coordsDict?["longitude"] as? NSNumber)?.doubleValue ?? 0
            )
            self.location = BGGeo.LocationEvent(TSLocationEvent(locationDictionary: obj.location, location: clLocation))
            self.geofence = BGGeo.Geofence(obj.geofence)
            self.extras = obj.extras as? [String: Any]

            if let lat = coordsDict?["latitude"] as? Double,
               let lng = coordsDict?["longitude"] as? Double {
                self.triggerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            } else {
                self.triggerCoordinate = nil
            }
            let heading = (coordsDict?["heading"] as? NSNumber)?.doubleValue
            self.triggerHeading = (heading != nil && heading! >= 0) ? heading : nil
        }
    }
}
