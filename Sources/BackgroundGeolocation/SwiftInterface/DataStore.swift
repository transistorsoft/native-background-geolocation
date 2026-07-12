//
//  DataStore.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public class DataStore {
        /// Sort-order constant for `all`: oldest first.
        public static let ORDER_ASC = 1
        /// Sort-order constant for `all`: newest first.
        public static let ORDER_DESC = -1

        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        /// Fetch persisted locations, optionally paged. Omit all arguments for the full (unbounded)
        /// table, or supply paging bounds — `limit`, `offset` (or the 0-indexed `page` convenience),
        /// and `order` (`ORDER_ASC` oldest first / `ORDER_DESC` newest first) — to drain a large
        /// table in slices.
        ///
        /// ```swift
        /// // One page of 500, newest first
        /// let page = try await bgGeo.store.all(limit: 500, page: 0, order: BGGeo.DataStore.ORDER_DESC)
        /// ```
        public func all(
            limit: Int = 0,
            offset: Int = 0,
            page: Int = 0,
            order: Int = 0
        ) async throws -> [[String: Any]] {
            try await withCheckedThrowingContinuation { continuation in
                manager.getLocations(
                    buildLocationQuery(limit: limit, offset: offset, page: page, order: order),
                    success: { locations in
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

        private func buildLocationQuery(limit: Int, offset: Int, page: Int, order: Int) -> LocationQuery {
            let q = LocationQuery()
            if limit > 0 { q.limit = Int32(limit) }
            if offset > 0 {
                q.offset = Int32(offset)
            } else if page > 0 && limit > 0 {
                q.offset = Int32(page * limit)
            }
            // Only ±1 are meaningful; anything else leaves order unspecified (config fallback).
            if order == DataStore.ORDER_ASC || order == DataStore.ORDER_DESC {
                q.order = SQLQueryOrder(rawValue: order)
            }
            return q
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
