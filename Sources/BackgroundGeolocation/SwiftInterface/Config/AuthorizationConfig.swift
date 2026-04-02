//
//  AuthorizationConfig.swift
//  TSLocationManager
//

import Foundation
import TSLocationManager

extension BGGeo {
    public enum AuthorizationStrategy: String {
        case jwt = "JWT"
        case sas = "SAS"

        init?(_ value: String?) {
            guard let value else { return nil }
            self.init(rawValue: value.uppercased())
        }
    }

    public class AuthorizationConfig {
        private let module: TSAuthorizationConfig
        init(_ module: TSAuthorizationConfig) { self.module = module }

        public var strategy: AuthorizationStrategy? {
            get { AuthorizationStrategy(module.strategy) }
            set { module.strategy = newValue?.rawValue }
        }
        public var accessToken: String? {
            get { module.accessToken }
            set { module.accessToken = newValue }
        }
        public var refreshToken: String? {
            get { module.refreshToken }
            set { module.refreshToken = newValue }
        }
        public var refreshPayload: [String: Any]? {
            get { module.refreshPayload }
            set { module.refreshPayload = newValue }
        }
        public var refreshHeaders: [String: String]? {
            get { module.refreshHeaders }
            set { module.refreshHeaders = newValue }
        }
        public var refreshUrl: String? {
            get { module.refreshUrl }
            set { module.refreshUrl = newValue }
        }
        public var expires: TimeInterval {
            get { module.expires }
            set { module.expires = newValue }
        }

        public func update(with dictionary: [AnyHashable: Any]) {
            module.update(with: dictionary)
        }
    }
}
