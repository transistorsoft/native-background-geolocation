//
//  AppConfig.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public class AppConfig {
        private let module: TSAppConfig
        init(_ module: TSAppConfig) { self.module = module }

        public var stopOnTerminate: Bool {
            get { module.stopOnTerminate }
            set { module.stopOnTerminate = newValue }
        }
        public var startOnBoot: Bool {
            get { module.startOnBoot }
            set { module.startOnBoot = newValue }
        }
        public var preventSuspend: Bool {
            get { module.preventSuspend }
            set { module.preventSuspend = newValue }
        }
        public var heartbeatInterval: TimeInterval {
            get { module.heartbeatInterval }
            set { module.heartbeatInterval = newValue }
        }
        public var schedule: [Any] {
            get { (module.schedule as [Any]?) ?? [] }
            set { module.schedule = newValue }
        }
    }
}
