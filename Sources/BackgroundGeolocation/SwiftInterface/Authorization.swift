//
//  Authorization.swift
//  TSLocationManager
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    public class Authorization {
        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        public func getState() -> BGGeo.ProviderChangeEvent {
            BGGeo.ProviderChangeEvent(manager.getProviderState())
        }

        public func requestPermission() async throws -> CLAuthorizationStatus {
            try await withCheckedThrowingContinuation { continuation in
                manager.requestPermission(
                    { status in
                        let authStatus = CLAuthorizationStatus(rawValue: status.int32Value) ?? .notDetermined
                        continuation.resume(returning: authStatus)
                    },
                    failure: { status in
                        continuation.resume(throwing: NSError(
                            domain: "BGGeo", code: status.intValue,
                            userInfo: [NSLocalizedDescriptionKey: "Permission denied: \(status)"]
                        ))
                    }
                )
            }
        }

        public func requestTemporaryFullAccuracy(purpose: String) async throws -> CLAccuracyAuthorization {
            try await withCheckedThrowingContinuation { continuation in
                manager.requestTemporaryFullAccuracy(purpose,
                    success: {
                        let accuracy = CLAccuracyAuthorization(rawValue: Int($0)) ?? .reducedAccuracy
                        continuation.resume(returning: accuracy)
                    },
                    failure: { continuation.resume(throwing: $0) }
                )
            }
        }
    }
}
