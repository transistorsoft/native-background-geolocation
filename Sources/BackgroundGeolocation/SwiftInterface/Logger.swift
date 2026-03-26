//
//  Logger.swift
//  TSLocationManager
//

import Foundation
import AudioToolbox
import TSLocationManager

extension BGGeo {
    public class Logger {
        private let manager = BackgroundGeolocation.sharedInstance()

        init() {}

        public func getLog() async throws -> String {
            try await withCheckedThrowingContinuation { continuation in
                manager.getLog(
                    { log in continuation.resume(returning: log) },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        public func emailLog(to email: String) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                manager.emailLog(email,
                    success: { continuation.resume() },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        @discardableResult
        public func destroyLog() -> Bool {
            manager.destroyLog()
        }

        public var logLevel: BGGeo.LogLevel {
            get { BGGeo.LogLevel(TSConfig.sharedInstance().logger.logLevel) }
            set { manager.setLogLevel(newValue.objc) }
        }

        /// Log a message at the given level.
        public func log(_ level: BGGeo.LogLevel, message: String) {
            manager.log(level.tag, message: message)
        }

        public func debug(_ message: String)  { log(.debug,   message: message) }
        public func info(_ message: String)   { log(.info,    message: message) }
        public func warn(_ message: String)   { log(.warning, message: message) }
        public func error(_ message: String)  { log(.error,   message: message) }
        public func notice(_ message: String) { log(.info,    message: message) }

        public func playSound(_ soundId: SystemSoundID) {
            manager.playSound(soundId)
        }
    }
}
