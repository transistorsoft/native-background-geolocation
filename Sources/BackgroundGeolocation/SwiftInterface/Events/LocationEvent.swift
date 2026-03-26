//
//  LocationEvent.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2025-08-17.
//  Copyright © 2025 Christopher Scott. All rights reserved.
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    public struct LocationEvent {
        public struct Coords {
            public let latitude: Double
            public let longitude: Double
            public let accuracy: Double?
            public let speed: Double?
            public let speedAccuracy: Double?
            public let altitude: Double?
            public let altitudeAccuracy: Double?
            public let ellipsoidalAltitude: Double?
            public let heading: Double?
            public let headingAccuracy: Double?
            public let floor: Int?
        }

        public struct Battery {
            public let level: Double?
            public let isCharging: Bool?
        }

        public struct Activity {
            public let type: String?
            public let confidence: Int?
        }

        public let timestamp: Date?
        public let timestampString: String

        public let data: [String: Any]
        public let location: CLLocation
        public let event: String?
        public let isMoving: Bool
        public let sample: Bool
        public let odometer: Double?
        public let odometerError: Double?

        public let coords: Coords?
        public let battery: Battery?
        public let activity: Activity?

        public init(_ obj: TSLocationEvent) {
            self.timestampString = obj.timestamp
            self.timestamp = ISO8601DateFormatter.fullParsing.date(from: obj.timestamp)
            self.data = obj.toDictionary() as? [String: Any] ?? [:]
            self.location = obj.location
            self.isMoving = obj.isMoving
            self.sample = data.keys.contains("sample")
            self.odometer = data["odometer"] as? Double
            self.odometerError = data["odometer_error"] as? Double
            self.event = obj.event

            if let c = data["coords"] as? [String: Any] {
                coords = Coords(
                    latitude: c.double("latitude"),
                    longitude: c.double("longitude"),
                    accuracy: c.doubleOpt("accuracy"),
                    speed: c.doubleOpt("speed"),
                    speedAccuracy: c.doubleOpt("speed_accuracy"),
                    altitude: c.doubleOpt("altitude"),
                    altitudeAccuracy: c.doubleOpt("altitude_accuracy"),
                    ellipsoidalAltitude: c.doubleOpt("ellipsoidal_altitude"),
                    heading: c.doubleOpt("heading"),
                    headingAccuracy: c.doubleOpt("heading_accuracy"),
                    floor: c.intOpt("floor")
                )
            } else {
                coords = nil
            }

            if let b = data["battery"] as? [String: Any] {
                battery = Battery(
                    level: b.doubleOpt("level"),
                    isCharging: b.boolOpt("is_charging")
                )
            } else {
                battery = nil
            }

            if let a = data["activity"] as? [String: Any] {
                activity = Activity(
                    type: a["type"] as? String,
                    confidence: a.intOpt("confidence")
                )
            } else {
                activity = nil
            }
        }
    }
}

// MARK: - Parsing helpers

internal extension Dictionary where Key == String, Value == Any {
    func double(_ key: String) -> Double {
        (self[key] as? NSNumber)?.doubleValue
        ?? Double(self[key] as? String ?? "")
        ?? 0
    }
    func doubleOpt(_ key: String) -> Double? {
        if let n = self[key] as? NSNumber { return n.doubleValue }
        if let s = self[key] as? String, let d = Double(s) { return d }
        return nil
    }
    func intOpt(_ key: String) -> Int? {
        if let n = self[key] as? NSNumber { return n.intValue }
        if let s = self[key] as? String, let i = Int(s) { return i }
        return nil
    }
    func boolOpt(_ key: String) -> Bool? {
        if let n = self[key] as? NSNumber { return n.boolValue }
        if let s = self[key] as? String {
            switch s.lowercased() {
            case "true", "1": return true
            case "false", "0": return false
            default: break
            }
        }
        return nil
    }
}

// MARK: - ISO8601 with fractional seconds

internal extension ISO8601DateFormatter {
    static let fullParsing: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}
