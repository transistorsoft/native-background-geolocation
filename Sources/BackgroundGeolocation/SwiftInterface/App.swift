//
//  App.swift
//  TSLocationManager
//

import UIKit
import TSLocationManager

extension BGGeo {
    public class App {
        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        public func createBackgroundTask() -> UIBackgroundTaskIdentifier {
            manager.createBackgroundTask()
        }

        public func stopBackgroundTask(_ taskId: UIBackgroundTaskIdentifier) {
            manager.stopBackgroundTask(taskId)
        }

        public var isPowerSaveMode: Bool {
            manager.isPowerSaveMode()
        }
    }
}
