//
//  HttpEvent.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import TSLocationManager

extension BGGeo {
    public struct HttpEvent: Sendable {
        public let isSuccess: Bool
        public let statusCode: Int
        public let responseText: String
        public let error: String?

        public init(_ obj: TSHttpEvent) {
            self.isSuccess = obj.isSuccess
            self.statusCode = Int(obj.statusCode)
            self.responseText = obj.responseText
            self.error = obj.error?.localizedDescription
        }
    }
}
