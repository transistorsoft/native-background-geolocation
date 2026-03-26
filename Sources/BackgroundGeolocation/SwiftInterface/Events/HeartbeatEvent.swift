//
//  HeartbeatEvent.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    public struct HeartbeatEvent {
        /// The raw `CLLocation` from CoreLocation.
        public let location: CLLocation

        /// The full location data dictionary (same shape as HTTP post body).
        public let data: [String: Any]

        public init(_ obj: TSHeartbeatEvent) {
            self.location = obj.location
            self.data = obj.data as? [String: Any] ?? [:]
        }
    }
}
