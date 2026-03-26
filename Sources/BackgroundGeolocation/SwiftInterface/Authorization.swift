//
//  Authorization.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public class Authorization {
        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        public func getState() -> BGGeo.ProviderChangeEvent {
            BGGeo.ProviderChangeEvent(manager.getProviderState())
        }

        public func requestPermission() async throws -> Int {
            try await withCheckedThrowingContinuation { continuation in
                manager.requestPermission(
                    { status in continuation.resume(returning: status.intValue) },
                    failure: { status in
                        continuation.resume(throwing: NSError(
                            domain: "BGGeo", code: status.intValue,
                            userInfo: [NSLocalizedDescriptionKey: "Permission denied: \(status)"]
                        ))
                    }
                )
            }
        }

        public func requestTemporaryFullAccuracy(purpose: String) async throws -> Int {
            try await withCheckedThrowingContinuation { continuation in
                manager.requestTemporaryFullAccuracy(purpose,
                    success: { continuation.resume(returning: Int($0)) },
                    failure: { continuation.resume(throwing: $0) }
                )
            }
        }
    }
}
