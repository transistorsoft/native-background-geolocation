//
//  Authorization.swift
//  TSLocationManager
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    /// A specific permission to request via ``Authorization/requestPermission(_:)`` (WO-007).
    /// Omitting it requests everything the current config requires — location per
    /// `locationAuthorizationRequest`, then motion — exactly like `start()`.
    public enum Permission: String {
        case location
        case motion
    }

    /// The cross-platform permission-status domain.  `CLAuthorizationStatus` and
    /// `CMAuthorizationStatus` both map into it positionally
    /// (`CMAuthorizationStatus.authorized` ⇒ ``always``).
    public enum PermissionStatus: Int {
        case notDetermined = 0
        case restricted = 1
        case denied = 2
        case always = 3
        case whenInUse = 4
        /// Permanently denied — only the app-settings screen can recover.
        ///
        /// Android: reported after the second refusal; further requests silently no-op.
        /// iOS (WO-014): reported for ANY motion denial, because CoreMotion has no request
        /// API and never re-prompts — an iOS motion denial is strictly more permanent than
        /// Android's. Location on iOS never reports this; CoreLocation has no such state.
        case deniedAlways = 5

        static func from(_ value: NSNumber) -> PermissionStatus {
            PermissionStatus(rawValue: value.intValue) ?? .denied
        }
    }
}

extension BGGeo {
    public class Authorization {
        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        public func getState() -> BGGeo.ProviderChangeEvent {
            BGGeo.ProviderChangeEvent(manager.getProviderState())
        }

        /// (WO-007) Request permissions.  Denial is an expected outcome, reported as a
        /// value — never thrown (aligned with the Kotlin API).  Omit `permission` for
        /// the config-driven everything request, which resolves with the LOCATION
        /// status; `.location` and `.motion` request each permission separately.
        public func requestPermission(_ permission: Permission? = nil) async -> PermissionStatus {
            await withCheckedContinuation { continuation in
                manager.requestPermission(permission?.rawValue,
                    success: { continuation.resume(returning: PermissionStatus.from($0)) },
                    failure: { continuation.resume(returning: PermissionStatus.from($0)) }
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
