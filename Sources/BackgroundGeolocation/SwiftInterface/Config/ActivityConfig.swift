//
//  ActivityConfig.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public class ActivityConfig {
        private let module: TSActivityConfig
        init(_ module: TSActivityConfig) { self.module = module }

        public var stopDetectionDelay: TimeInterval {
            get { module.stopDetectionDelay }
            set { module.stopDetectionDelay = newValue }
        }
        public var activityRecognitionInterval: TimeInterval {
            get { module.activityRecognitionInterval }
            set { module.activityRecognitionInterval = newValue }
        }
        public var minimumActivityRecognitionConfidence: Int {
            get { Int(module.minimumActivityRecognitionConfidence) }
            set { module.minimumActivityRecognitionConfidence = newValue }
        }
        public var disableMotionActivityUpdates: Bool {
            get { module.disableMotionActivityUpdates }
            set { module.disableMotionActivityUpdates = newValue }
        }
        public var disableStopDetection: Bool {
            get { module.disableStopDetection }
            set { module.disableStopDetection = newValue }
        }
        public var stopOnStationary: Bool {
            get { module.stopOnStationary }
            set { module.stopOnStationary = newValue }
        }
        public var triggerActivities: String {
            get { module.triggerActivities }
            set { module.triggerActivities = newValue }
        }
    }
}
