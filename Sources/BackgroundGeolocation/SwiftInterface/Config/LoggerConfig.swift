//
//  LoggerConfig.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public enum LogLevel: Int {
        case off = 0
        case error = 1
        case warning = 2
        case info = 3
        case debug = 4
        case verbose = 5

        init(_ value: TSLogLevel) { self = LogLevel(rawValue: value.rawValue) ?? .off }
        var objc: TSLogLevel { TSLogLevel(rawValue: rawValue)! }

        /// The string tag passed to the ObjC `log:message:` method.
        var tag: String {
            switch self {
            case .off:     return "off"
            case .error:   return "error"
            case .warning: return "warn"
            case .info:    return "info"
            case .debug:   return "debug"
            case .verbose: return "debug"
            }
        }
    }

    public class LoggerConfig {
        private let module: TSLoggerConfig
        init(_ module: TSLoggerConfig) { self.module = module }

        public var debug: Bool {
            get { module.debug }
            set { module.debug = newValue }
        }
        public var logLevel: LogLevel {
            get { LogLevel(module.logLevel) }
            set { module.logLevel = newValue.objc }
        }
        public var logMaxDays: Int {
            get { Int(module.logMaxDays) }
            set { module.logMaxDays = newValue }
        }
    }
}
