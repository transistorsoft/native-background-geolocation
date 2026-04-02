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

        public static let ORDER_ASC = 1
        public static let ORDER_DESC = -1

        init() {}

        // MARK: - Log Retrieval

        public func getLog(
            start: Int64 = 0,
            end: Int64 = 0,
            order: Int = Logger.ORDER_ASC,
            limit: Int = 0
        ) async throws -> String {
            try await withCheckedThrowingContinuation { continuation in
                if let query = self.buildQuery(start: start, end: end, order: order, limit: limit) {
                    manager.getLog(query,
                        success: { log in continuation.resume(returning: log) },
                        failure: { error in
                            continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: error]))
                        }
                    )
                } else {
                    manager.getLog(
                        { log in continuation.resume(returning: log) },
                        failure: { error in
                            continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: error]))
                        }
                    )
                }
            }
        }

        public func emailLog(
            to email: String,
            start: Int64 = 0,
            end: Int64 = 0,
            order: Int = Logger.ORDER_ASC,
            limit: Int = 0
        ) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                if let query = self.buildQuery(start: start, end: end, order: order, limit: limit) {
                    manager.emailLog(email, query: query,
                        success: { continuation.resume() },
                        failure: { error in
                            continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: error]))
                        }
                    )
                } else {
                    manager.emailLog(email,
                        success: { continuation.resume() },
                        failure: { error in
                            continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: error]))
                        }
                    )
                }
            }
        }

        public func uploadLog(
            url: String,
            start: Int64 = 0,
            end: Int64 = 0,
            order: Int = Logger.ORDER_ASC,
            limit: Int = 0
        ) async throws {
            let query = self.buildQuery(start: start, end: end, order: order, limit: limit) ?? LogQuery()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                manager.uploadLog(url, query: query,
                    success: { continuation.resume() },
                    failure: { error in
                        continuation.resume(throwing: NSError(domain: "BGGeo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: error]))
                    }
                )
            }
        }

        // MARK: - Log Management

        public func destroyLog() async throws {
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

        // MARK: - Private

        private func buildQuery(start: Int64, end: Int64, order: Int, limit: Int) -> LogQuery? {
            guard start != 0 || end != 0 || order != Logger.ORDER_ASC || limit != 0 else { return nil }
            let q = LogQuery()
            q.start = Double(start)
            q.end = Double(end)
            q.order = SQLQueryOrder(rawValue: order)
            q.limit = Int32(limit)
            return q
        }
    }
}
