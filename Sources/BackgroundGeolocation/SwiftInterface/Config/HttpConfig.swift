//
//  HttpConfig.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    /// HTTP method for location uploads.
    public enum HttpMethod: String {
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
    }

    public class HttpConfig {
        private let module: TSHttpConfig
        init(_ module: TSHttpConfig) { self.module = module }

        public var url: String {
            get { module.url }
            set { module.url = newValue }
        }
        /// The HTTP method. Accepts `.post`, `.put`, `.patch` or a raw `String`.
        public var method: HttpMethod {
            get { HttpMethod(rawValue: module.method) ?? .post }
            set { module.method = newValue.rawValue }
        }
        public var rootProperty: String {
            get { module.rootProperty }
            set { module.rootProperty = newValue }
        }
        public var headers: [String: Any] {
            get { module.headers }
            set { module.headers = newValue as [String: any Sendable] }
        }
        public var params: [String: Any] {
            get { module.params }
            set { module.params = newValue as [String: any Sendable] }
        }
        public var timeout: Int {
            get { Int(module.timeout) }
            set { module.timeout = newValue }
        }
        public var autoSync: Bool {
            get { module.autoSync }
            set { module.autoSync = newValue }
        }
        public var autoSyncThreshold: Int {
            get { Int(module.autoSyncThreshold) }
            set { module.autoSyncThreshold = newValue }
        }
        public var batchSync: Bool {
            get { module.batchSync }
            set { module.batchSync = newValue }
        }
        public var maxBatchSize: Int {
            get { Int(module.maxBatchSize) }
            set { module.maxBatchSize = newValue }
        }
        public var disableAutoSyncOnCellular: Bool {
            get { module.disableAutoSyncOnCellular }
            set { module.disableAutoSyncOnCellular = newValue }
        }
    }
}
