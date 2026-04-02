//
//  DeviceSettings.swift
//  TSLocationManager
//

import TSLocationManager

extension BGGeo {
    public class DeviceSettings {
        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        /// Returns `true` if the device is currently in Low Power Mode.
        ///
        /// Low Power Mode is a device-wide setting, independent of any individual app.
        public var isPowerSaveMode: Bool {
            manager.isPowerSaveMode()
        }
    }
}
