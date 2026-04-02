//
//  GeofenceManager.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public class GeofenceManager {
        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        public func add(_ geofence: BGGeo.Geofence) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                manager.add(geofence.toTSGeofence(),
                    success: { continuation.resume() },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        public func addAll(_ geofences: [BGGeo.Geofence]) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                manager.addGeofences(geofences.map { $0.toTSGeofence() },
                    success: { continuation.resume() },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        public func remove(_ identifier: String) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                manager.removeGeofence(identifier,
                    success: { continuation.resume() },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        public func removeAll(_ identifiers: [String]? = nil) async throws {
            if let identifiers {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    manager.removeGeofences(identifiers,
                        success: { continuation.resume() },
                        failure: { error in
                            continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: error]))
                        }
                    )
                }
            } else {
                manager.removeGeofences()
            }
        }

        public func getAll() async -> [BGGeo.Geofence] {
            (manager.getGeofences() as? [TSGeofence] ?? []).map { BGGeo.Geofence($0) }
        }

        public func get(_ identifier: String) async throws -> BGGeo.Geofence {
            try await withCheckedThrowingContinuation { continuation in
                manager.getGeofence(identifier,
                    success: { geofence in continuation.resume(returning: BGGeo.Geofence(geofence)) },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        public func exists(_ identifier: String) async -> Bool {
            await withCheckedContinuation { continuation in
                manager.geofenceExists(identifier) { exists in
                    continuation.resume(returning: exists)
                }
            }
        }
    }
}
