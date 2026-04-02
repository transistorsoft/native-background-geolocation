//
//  Config.swift
//  TSLocationManager
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    public enum TrackingMode: Int {
        case geofence = 0
        case location = 1

        init(_ value: TSTrackingMode) { self = TrackingMode(rawValue: value.rawValue) ?? .location }
        var objc: TSTrackingMode { TSTrackingMode(rawValue: rawValue)! }
    }

    public class Config {
        private let tsConfig = TSConfig.sharedInstance()

        public let http: BGGeo.HttpConfig
        public let geolocation: BGGeo.GeolocationConfig
        public let persistence: BGGeo.PersistenceConfig
        public let activity: BGGeo.ActivityConfig
        public let app: BGGeo.AppConfig
        public let authorization: BGGeo.AuthorizationConfig
        public let logger: BGGeo.LoggerConfig

        init() {
            let c = TSConfig.sharedInstance()
            http = BGGeo.HttpConfig(c.http)
            geolocation = BGGeo.GeolocationConfig(c.geolocation)
            persistence = BGGeo.PersistenceConfig(c.persistence)
            activity = BGGeo.ActivityConfig(c.activity)
            app = BGGeo.AppConfig(c.app)
            authorization = BGGeo.AuthorizationConfig(c.authorization)
            logger = BGGeo.LoggerConfig(c.logger)
        }

        // MARK: - Query

        public var isFirstBoot: Bool { tsConfig.isFirstBoot() }

        // MARK: - Edit

        public func edit(_ block: @escaping (Config) -> Void) {
            tsConfig.batchUpdate { _ in block(self) }
        }

        // MARK: - Reset

        public func reset() { tsConfig.reset() }

        // MARK: - Serialization

        public func toDictionary() -> [String: Any] {
            tsConfig.toDictionary() as? [String: Any] ?? [:]
        }

        public func toJson() -> String {
            tsConfig.toJson()
        }
    }
}
