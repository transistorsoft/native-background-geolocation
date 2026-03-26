//
//  GeolocationConfig.swift
//  TSLocationManager
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    /// Location authorization level to request from the user.
    public enum LocationAuthorizationRequest: String {
        case always = "Always"
        case whenInUse = "WhenInUse"
        case any = "Any"
    }

    public class GeolocationConfig {
        private let module: TSGeolocationConfig
        public let filter: BGGeo.LocationFilterConfig

        init(_ module: TSGeolocationConfig) {
            self.module = module
            self.filter = BGGeo.LocationFilterConfig(module.filter)
        }

        // MARK: - CoreLocation

        public var desiredAccuracy: CLLocationAccuracy {
            get { module.desiredAccuracy }
            set { module.desiredAccuracy = newValue }
        }
        public var distanceFilter: CLLocationDistance {
            get { module.distanceFilter }
            set { module.distanceFilter = newValue }
        }
        public var useSignificantChangesOnly: Bool {
            get { module.useSignificantChangesOnly }
            set { module.useSignificantChangesOnly = newValue }
        }
        public var pausesLocationUpdatesAutomatically: Bool {
            get { module.pausesLocationUpdatesAutomatically }
            set { module.pausesLocationUpdatesAutomatically = newValue }
        }
        public var showsBackgroundLocationIndicator: Bool {
            get { module.showsBackgroundLocationIndicator }
            set { module.showsBackgroundLocationIndicator = newValue }
        }
        public var activityType: CLActivityType {
            get { module.activityType }
            set { module.activityType = newValue }
        }
        public var locationTimeout: TimeInterval {
            get { module.locationTimeout }
            set { module.locationTimeout = newValue }
        }

        // MARK: - Elasticity & Motion Detection

        public var stopTimeout: TimeInterval {
            get { module.stopTimeout }
            set { module.stopTimeout = newValue }
        }
        public var stationaryRadius: CLLocationDistance {
            get { module.stationaryRadius }
            set { module.stationaryRadius = newValue }
        }
        public var stopAfterElapsedMinutes: TimeInterval {
            get { module.stopAfterElapsedMinutes }
            set { module.stopAfterElapsedMinutes = newValue }
        }
        public var disableElasticity: Bool {
            get { module.disableElasticity }
            set { module.disableElasticity = newValue }
        }
        public var elasticityMultiplier: Double {
            get { module.elasticityMultiplier }
            set { module.elasticityMultiplier = newValue }
        }

        // MARK: - Location Authorization

        /// The authorization level to request: `.always` or `.whenInUse`.
        public var locationAuthorizationRequest: LocationAuthorizationRequest {
            get { LocationAuthorizationRequest(rawValue: module.locationAuthorizationRequest) ?? .always }
            set { module.locationAuthorizationRequest = newValue.rawValue }
        }
        public var disableLocationAuthorizationAlert: Bool {
            get { module.disableLocationAuthorizationAlert }
            set { module.disableLocationAuthorizationAlert = newValue }
        }
        public var locationAuthorizationAlert: [String: Any] {
            get { module.locationAuthorizationAlert as? [String: Any] ?? [:] }
            set { module.locationAuthorizationAlert = newValue as [AnyHashable: Any] }
        }

        // MARK: - Geofencing

        public var geofenceProximityRadius: CLLocationDistance {
            get { module.geofenceProximityRadius }
            set { module.geofenceProximityRadius = newValue }
        }
        public var geofenceInitialTriggerEntry: Bool {
            get { module.geofenceInitialTriggerEntry }
            set { module.geofenceInitialTriggerEntry = newValue }
        }

        // MARK: - Metadata

        public var enableTimestampMeta: Bool {
            get { module.enableTimestampMeta }
            set { module.enableTimestampMeta = newValue }
        }
    }
}
