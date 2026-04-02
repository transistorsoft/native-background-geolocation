//
//  Sensors.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public class Sensors {
        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        public var hasAccelerometer: Bool { manager.isAccelerometerAvailable() }
        public var hasGyroscope: Bool { manager.isGyroAvailable() }
        public var hasMagnetometer: Bool { manager.isMagnetometerAvailable() }
        public var hasSignificantMotion: Bool { manager.isMotionHardwareAvailable() }
    }
}
