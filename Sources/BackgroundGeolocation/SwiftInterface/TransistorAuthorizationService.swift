//
//  TransistorAuthorizationService.swift
//  TSLocationManager
//
//  Swift convenience wrapper around TransistorAuthorizationToken for
//  the Transistor demo server (tracker.transistorsoft.com).
//

import Foundation
import TSLocationManager

extension BGGeo {
    /// Lightweight Swift struct wrapping the ObjC `TransistorAuthorizationToken`.
    public struct TransistorToken {
        public let accessToken: String
        public let refreshToken: String
        public let expires: Int
        public let apiUrl: String
        public let refreshUrl: String

        init(_ obj: TransistorAuthorizationToken) {
            self.accessToken  = obj.accessToken
            self.refreshToken = obj.refreshToken
            self.expires      = Int(obj.expires)
            self.apiUrl       = obj.apiUrl
            self.refreshUrl   = obj.refreshUrl
        }

        public func toDictionary() -> [String: Any] {
            return [
                "accessToken":  accessToken,
                "refreshToken": refreshToken,
                "expires":      expires,
                "refreshUrl":   refreshUrl
            ]
        }
    }

    /// Static service for fetching / caching / destroying Transistor demo-server auth tokens.
    ///
    /// ```swift
    /// let token = try await BGGeo.TransistorAuthorizationService.findOrCreateToken(
    ///     org: "my-org",
    ///     username: "my-user",
    ///     url: "https://tracker.transistorsoft.com"
    /// )
    /// print(token.accessToken)
    /// ```
    public enum TransistorAuthorizationService {

        /// Fetch a cached token or register a new one with the Transistor demo server.
        public static func findOrCreateToken(
            org: String,
            username: String,
            url: String,
            framework: String = "Swift"
        ) async throws -> BGGeo.TransistorToken {
            try await withCheckedThrowingContinuation { continuation in
                TransistorAuthorizationToken.findOrCreate(
                    withOrg: org,
                    username: username,
                    url: url,
                    framework: framework,
                    success: { token in
                        continuation.resume(returning: BGGeo.TransistorToken(token))
                    },
                    failure: { error in
                        continuation.resume(throwing: error)
                    }
                )
            }
        }

        /// Destroy the cached token for the given URL.
        public static func destroyToken(url: String) {
            TransistorAuthorizationToken.destroy(withUrl: url)
        }

        /// Check whether a cached token exists for the given host.
        public static func hasToken(forHost host: String) -> Bool {
            TransistorAuthorizationToken.hasToken(forHost: host)
        }
    }
}
