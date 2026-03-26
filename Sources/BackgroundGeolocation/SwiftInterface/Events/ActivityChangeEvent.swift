//
//  ActivityChangeEvent.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import TSLocationManager

extension BGGeo {
    public struct ActivityChangeEvent: Sendable {
        public let activity: String
        public let confidence: Int

        public init(_ obj: TSActivityChangeEvent) {
            self.activity = obj.activity
            self.confidence = Int(obj.confidence)
        }
    }
}
