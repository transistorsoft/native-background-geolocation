//
//  Geofence.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    public struct Geofence {
        public enum EntryState {
            case outside
            case inside
        }

        public let identifier: String
        public let latitude: Double
        public let longitude: Double
        public let radius: Double
        public let notifyOnEntry: Bool
        public let notifyOnExit: Bool
        public let notifyOnDwell: Bool
        public let loiteringDelay: Double
        public let extras: [String: Any]?
        public let vertices: [[Double]]?
        public let isPolygon: Bool
        public let entryState: EntryState
        public let stateUpdatedAt: Date?
        public let hits: Int

        public var center: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        // MARK: - Public initializers (for creating geofences)

        /// Create a circular geofence.
        public init(
            identifier: String,
            radius: CLLocationDistance,
            latitude: CLLocationDegrees,
            longitude: CLLocationDegrees,
            notifyOnEntry: Bool = true,
            notifyOnExit: Bool = true,
            notifyOnDwell: Bool = false,
            loiteringDelay: Double = 0,
            extras: [String: Any]? = nil
        ) {
            self.identifier = identifier
            self.latitude = latitude
            self.longitude = longitude
            self.radius = radius
            self.notifyOnEntry = notifyOnEntry
            self.notifyOnExit = notifyOnExit
            self.notifyOnDwell = notifyOnDwell
            self.loiteringDelay = loiteringDelay
            self.extras = extras
            self.vertices = nil
            self.isPolygon = false
            self.entryState = .outside
            self.stateUpdatedAt = nil
            self.hits = 0
        }

        /// Create a polygon geofence.
        public init(
            identifier: String,
            vertices: [[Double]],
            notifyOnEntry: Bool = true,
            notifyOnExit: Bool = true,
            notifyOnDwell: Bool = false,
            loiteringDelay: Double = 0,
            extras: [String: Any]? = nil
        ) {
            self.identifier = identifier
            self.latitude = 0
            self.longitude = 0
            self.radius = 0
            self.notifyOnEntry = notifyOnEntry
            self.notifyOnExit = notifyOnExit
            self.notifyOnDwell = notifyOnDwell
            self.loiteringDelay = loiteringDelay
            self.extras = extras
            self.vertices = vertices
            self.isPolygon = true
            self.entryState = .outside
            self.stateUpdatedAt = nil
            self.hits = 0
        }

        // MARK: - Internal (hydrating from ObjC)

        init(_ obj: TSGeofence) {
            self.identifier = obj.identifier
            self.latitude = obj.latitude
            self.longitude = obj.longitude
            self.radius = obj.radius
            self.notifyOnEntry = obj.notifyOnEntry
            self.notifyOnExit = obj.notifyOnExit
            self.notifyOnDwell = obj.notifyOnDwell
            self.loiteringDelay = obj.loiteringDelay
            self.extras = obj.extras as? [String: Any]
            self.isPolygon = obj.isPolygon()
            self.entryState = obj.entryState == .inside ? .inside : .outside
            self.stateUpdatedAt = obj.stateUpdatedAt > 0 ? Date(timeIntervalSince1970: obj.stateUpdatedAt) : nil
            self.hits = obj.hits

            if let verts = obj.vertices {
                self.vertices = verts.map { $0.map { $0.doubleValue } }
            } else {
                self.vertices = nil
            }
        }

        // MARK: - Internal (converting back to ObjC)

        func toTSGeofence() -> TSGeofence {
            let nExtras = extras as [AnyHashable: Any]?
            if isPolygon {
                return .polygon(
                    identifier: identifier,
                    vertices: vertices ?? [],
                    notifyOnEntry: notifyOnEntry,
                    notifyOnExit: notifyOnExit,
                    notifyOnDwell: notifyOnDwell,
                    loiteringDelay: loiteringDelay,
                    extras: nExtras
                )
            } else {
                return .circle(
                    identifier: identifier,
                    radius: radius,
                    latitude: latitude,
                    longitude: longitude,
                    notifyOnEntry: notifyOnEntry,
                    notifyOnExit: notifyOnExit,
                    notifyOnDwell: notifyOnDwell,
                    loiteringDelay: loiteringDelay,
                    extras: nExtras
                )
            }
        }

        /// Convert vertices to CLLocationCoordinate2D array (for map overlays)
        public var coordinates: [CLLocationCoordinate2D]? {
            vertices?.compactMap { v in
                guard v.count >= 2 else { return nil }
                return CLLocationCoordinate2D(latitude: v[0], longitude: v[1])
            }
        }
    }
}
