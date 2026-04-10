//
//  PersistenceConfig.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public enum PersistMode: Int {
        case none = 0
        case location = 1
        case all = 2
        case geofence = -1

        init(_ value: TSPersistMode) { self = PersistMode(rawValue: value.rawValue) ?? .all }
        var objc: TSPersistMode { TSPersistMode(rawValue: rawValue)! }
    }

    /// Sort order for location records in the database.
    public enum LocationsOrderDirection: String {
        case ascending = "ASC"
        case descending = "DESC"
    }

    public class PersistenceConfig {
        private let module: TSPersistenceConfig
        init(_ module: TSPersistenceConfig) { self.module = module }

        public var locationTemplate: String {
            get { module.locationTemplate }
            set { module.locationTemplate = newValue }
        }
        public var geofenceTemplate: String {
            get { module.geofenceTemplate }
            set { module.geofenceTemplate = newValue }
        }
        public var timestampFormat: String {
            get { module.timestampFormat }
            set { module.timestampFormat = newValue }
        }
        public var maxDaysToPersist: Int {
            get { Int(module.maxDaysToPersist) }
            set { module.maxDaysToPersist = newValue }
        }
        public var maxRecordsToPersist: Int {
            get { Int(module.maxRecordsToPersist) }
            set { module.maxRecordsToPersist = newValue }
        }
        /// Sort order for location records: `.ascending` or `.descending`.
        public var locationsOrderDirection: LocationsOrderDirection {
            get { LocationsOrderDirection(rawValue: module.locationsOrderDirection) ?? .ascending }
            set { module.locationsOrderDirection = newValue.rawValue }
        }
        public var persistMode: PersistMode {
            get { PersistMode(module.persistMode) }
            set { module.persistMode = newValue.objc }
        }
        public var extras: [String: Any] {
            get { module.extras }
            set { module.extras = newValue as [String: any Sendable] }
        }
    }
}
