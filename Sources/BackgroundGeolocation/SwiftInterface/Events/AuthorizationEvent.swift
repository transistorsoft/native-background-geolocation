//
//  AuthorizationEvent.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import TSLocationManager

extension BGGeo {
    public struct AuthorizationEvent {
        public let status: Int
        public let error: NSError?
        public let response: [String: Any]

        /// Whether the authorization request succeeded (HTTP 200).
        public var isSuccess: Bool { status == 200 }

        public init(_ obj: TSAuthorizationEvent) {
            self.status = Int(obj.status)
            self.error = obj.error as NSError?
            self.response = obj.response as? [String: Any] ?? [:]
        }
    }
}
