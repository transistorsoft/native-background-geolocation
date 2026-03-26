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

        public var isMotionHardwareAvailable: Bool { manager.isMotionHardwareAvailable() }
        public var isDeviceMotionAvailable: Bool { manager.isDeviceMotionAvailable() }
        public var isAccelerometerAvailable: Bool { manager.isAccelerometerAvailable() }
        public var isGyroAvailable: Bool { manager.isGyroAvailable() }
        public var isMagnetometerAvailable: Bool { manager.isMagnetometerAvailable() }
    }
}
