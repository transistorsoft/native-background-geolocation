//
//  LocationFilterConfig.swift
//  TSLocationManager
//

import Foundation
import CoreLocation
import TSLocationManager

extension BGGeo {
    public enum LocationFilterPolicy: Int {
        case passThrough = 0
        case adjust = 1
        case conservative = 2

        init(_ value: TSLocationFilterPolicy) { self = LocationFilterPolicy(rawValue: value.rawValue) ?? .conservative }
        var objc: TSLocationFilterPolicy { TSLocationFilterPolicy(rawValue: rawValue)! }
    }

    public enum KalmanProfile: Int {
        case `default` = 0
        case aggressive = 1
        case conservative = 2

        init(_ value: TSKalmanProfile) { self = KalmanProfile(rawValue: value.rawValue) ?? .default }
        var objc: TSKalmanProfile { TSKalmanProfile(rawValue: rawValue)! }
    }

    public class LocationFilterConfig {
        private let module: TSLocationFilterConfig
        init(_ module: TSLocationFilterConfig) { self.module = module }

        public var useKalman: Bool {
            get { module.useKalman }
            set { module.useKalman = newValue }
        }
        public var kalmanProfile: KalmanProfile {
            get { KalmanProfile(module.kalmanProfile) }
            set { module.kalmanProfile = newValue.objc }
        }
        public var kalmanDebug: Bool {
            get { module.kalmanDebug }
            set { module.kalmanDebug = newValue }
        }
        public var policy: LocationFilterPolicy {
            get { LocationFilterPolicy(module.policy) }
            set { module.policy = newValue.objc }
        }
        public var maxImpliedSpeed: Double {
            get { module.maxImpliedSpeed }
            set { module.maxImpliedSpeed = newValue }
        }
        public var maxBurstDistance: Double {
            get { module.maxBurstDistance }
            set { module.maxBurstDistance = newValue }
        }
        public var burstWindow: Double {
            get { module.burstWindow }
            set { module.burstWindow = newValue }
        }
        public var rollingWindow: Int {
            get { Int(module.rollingWindow) }
            set { module.rollingWindow = newValue }
        }
        public var odometerUseKalmanFilter: Bool {
            get { module.odometerUseKalmanFilter }
            set { module.odometerUseKalmanFilter = newValue }
        }
        public var odometerAccuracyThreshold: CLLocationAccuracy {
            get { module.odometerAccuracyThreshold }
            set { module.odometerAccuracyThreshold = newValue }
        }
        public var trackingAccuracyThreshold: CLLocationAccuracy {
            get { module.trackingAccuracyThreshold }
            set { module.trackingAccuracyThreshold = newValue }
        }
        public var filterDebug: Bool {
            get { module.filterDebug }
            set { module.filterDebug = newValue }
        }
    }
}
