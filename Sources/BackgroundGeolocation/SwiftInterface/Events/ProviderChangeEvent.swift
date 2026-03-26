//
//  ProviderChangeEvent.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    public struct ProviderChangeEvent: Sendable {
        public let status: CLAuthorizationStatus
        public let accuracyAuthorization: Int
        public let gps: Bool
        public let network: Bool
        public let enabled: Bool

        public init(_ obj: TSProviderChangeEvent) {
            self.status = obj.status
            self.accuracyAuthorization = Int(obj.accuracyAuthorization)
            self.gps = obj.gps
            self.network = obj.network
            self.enabled = obj.enabled
        }
    }
}
