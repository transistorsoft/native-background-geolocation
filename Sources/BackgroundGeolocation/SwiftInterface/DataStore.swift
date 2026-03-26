//
//  DataStore.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public class DataStore {
        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        public func all() async throws -> [[String: Any]] {
            try await withCheckedThrowingContinuation { continuation in
                manager.getLocations(
                    { locations in
                        let result = (locations as? [[String: Any]]) ?? []
                        continuation.resume(returning: result)
                    },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        @discardableResult
        public func destroyAll() -> Bool {
            manager.destroyLocations()
        }

        public func destroyAll() async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                manager.destroyLocations(
                    { continuation.resume() },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        public func destroy(_ uuid: String) {
            manager.destroyLocation(uuid)
        }

        public func insert(_ params: [String: Any]) async throws -> String {
            try await withCheckedThrowingContinuation { continuation in
                manager.insertLocation(params,
                    success: { uuid in continuation.resume(returning: uuid) },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        public var count: Int {
            Int(manager.getCount())
        }

        public func sync() async throws -> [[String: Any]] {
            try await withCheckedThrowingContinuation { continuation in
                manager.sync(
                    { locations in
                        let result = (locations as? [[String: Any]]) ?? []
                        continuation.resume(returning: result)
                    },
                    failure: { error in continuation.resume(throwing: error) }
                )
            }
        }
    }
}
