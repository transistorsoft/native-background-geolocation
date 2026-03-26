//
//  BGGeo.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import CoreLocation
import TSLocationManager

public class BGGeo {
    public static let shared = BGGeo()

    private let manager = BackgroundGeolocation.sharedInstance()

    public let config = Config()
    public let logger = Logger()
    public let geofences = GeofenceManager()
    public let sensors = Sensors()
    public let app = App()
    public let store = DataStore()
    public let authorization = Authorization()

    private init() {}

    // MARK: - Core Lifecycle

    /// Initialize the SDK and apply configuration.
    ///
    /// - Parameters:
    ///   - reset: When `true` (default), config from the closure is applied on **every** launch.
    ///            When `false`, config is applied **only on first install**; subsequent launches use persisted config.
    ///   - transistorAuthorizationToken: Optional token from ``TransistorAuthorizationService``.
    ///            When provided, auto-configures `http.url` and `authorization` for the Transistor demo server.
    ///            Always applied regardless of `reset`, since tokens may refresh between launches.
    ///   - configure: Closure to set config properties. Executed inside a `batchUpdate`.
    ///
    /// ```swift
    /// // Standard: apply config every launch
    /// bgGeo.ready { config in
    ///     config.http.url = "https://example.com"
    ///     config.geolocation.distanceFilter = 50
    /// }
    ///
    /// // With Transistor demo token
    /// let token = try await TransistorAuthorizationService.findOrCreateToken(
    ///     org: "my-org", username: "my-user"
    /// )
    /// bgGeo.ready(transistorAuthorizationToken: token) { config in
    ///     config.geolocation.distanceFilter = 50
    /// }
    /// ```
    public func ready(
        reset: Bool = true,
        transistorAuthorizationToken token: TransistorToken? = nil,
        _ configure: @escaping (Config) -> Void
    ) {
        let tsConfig = TSConfig.sharedInstance()

        if tsConfig.isFirstBoot() {
            // First install: always apply config regardless of reset flag
            config.batchUpdate(configure)
        } else if reset {
            // Subsequent launch + reset: wipe persisted config, re-apply from closure
            tsConfig.resetConfig(true)
            config.batchUpdate(configure)
        }
        // else: subsequent launch + reset:false → skip closure, use persisted config

        // Token rewrite: always applies (even when reset:false skips the closure),
        // since tokens may refresh between launches.
        if let token {
            config.batchUpdate { config in
                config.http.url = token.apiUrl
                config.authorization.strategy = "jwt"
                config.authorization.accessToken = token.accessToken
                config.authorization.refreshToken = token.refreshToken
                config.authorization.refreshUrl = token.refreshUrl
                config.authorization.refreshPayload = ["refresh_token": "{refreshToken}"]
                config.authorization.expires = TimeInterval(token.expires)
            }
        }

        manager.ready()
    }


    /// Start location tracking.
    ///
    /// Currently resolves immediately after requesting the native SDK to start.
    /// A future version may wait for the first successful location or throw on authorization failure.
    public func start() async throws {
        manager.start()
    }

    public func stop() {
        manager.stop()
    }

    public func startSchedule() {
        manager.startSchedule()
    }

    public func stopSchedule() {
        manager.stopSchedule()
    }

    /// Start geofence-only tracking.
    ///
    /// Currently resolves immediately after requesting the native SDK to start.
    /// A future version may wait for confirmation or throw on authorization failure.
    public func startGeofences() async throws {
        manager.startGeofences()
    }

    public func changePace(_ isMoving: Bool) {
        manager.changePace(isMoving)
    }

    public var enabled: Bool {
        manager.enabled
    }

    // MARK: - Geolocation

    public func getCurrentPosition(
        timeout: TimeInterval = 10,
        desiredAccuracy: CLLocationAccuracy = 5,
        maximumAge: Int = 0,
        samples: Int = 3,
        allowStale: Bool = true,
        persist: Bool = true,
        label: String? = "getCurrentPosition",
        extras: [String: Any]? = nil
    ) async throws -> LocationEvent {
        try await withCheckedThrowingContinuation { continuation in
            let request = TSCurrentPositionRequest.make(
                type: .current,
                success: { continuation.resume(returning: LocationEvent($0)) },
                failure: { continuation.resume(throwing: $0) }
            )
            request.timeout = timeout
            request.desiredAccuracy = desiredAccuracy
            request.maximumAge = maximumAge
            request.samples = samples
            request.allowStale = allowStale
            request.persist = persist
            request.label = label
            request.extras = extras as NSDictionary? as? [String: any Sendable]
            manager.getCurrentPosition(request)
        }
    }

    public func setOdometer(
        _ value: CLLocationDistance,
        timeout: TimeInterval = 10,
        desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest,
        maximumAge: Int = 5000,
        samples: Int = 3,
        persist: Bool = true,
        extras: [String: Any]? = nil
    ) async throws -> LocationEvent {
        try await withCheckedThrowingContinuation { continuation in
            let request = TSCurrentPositionRequest.make(
                type: .odometer,
                success: { continuation.resume(returning: LocationEvent($0)) },
                failure: { continuation.resume(throwing: $0) }
            )
            request.timeout = timeout
            request.desiredAccuracy = desiredAccuracy
            request.maximumAge = maximumAge
            request.samples = samples
            request.persist = persist
            request.extras = extras as NSDictionary? as? [String: any Sendable]
            manager.setOdometer(value, request: request)
        }
    }

    public var odometer: CLLocationDistance {
        manager.getOdometer()
    }

    public func watchPosition(
        interval: Double = 1000,
        timeout: TimeInterval = 60,
        persist: Bool = false,
        extras: [String: Any]? = nil,
        success: @escaping (LocationEvent) -> Void,
        failure: @escaping (Error) -> Void
    ) -> Int {
        let request = TSWatchPositionRequest.make(
            interval: interval,
            success: { success(LocationEvent($0.locationEvent)) },
            failure: { failure($0) }
        )
        request.timeout = timeout
        request.persist = persist
        request.extras = extras as NSDictionary? as? [String: any Sendable]
        return manager.watchPosition(request)
    }

    public func stopWatchPosition(_ watchId: Int) {
        manager.stopWatchPosition(watchId)
    }

    public func getStationaryLocation() -> [String: Any]? {
        manager.getStationaryLocation() as? [String: Any]
    }

    // MARK: - Event Listeners

    @discardableResult
    public func onLocation(_ callback: @escaping (LocationEvent) -> Void) -> EventSubscription {
        let token = manager.onLocation({ callback(LocationEvent($0)) }, failure: { _ in })
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameLocation, token: token)
        }
    }

    @discardableResult
    public func onMotionChange(_ callback: @escaping (LocationEvent) -> Void) -> EventSubscription {
        let token = manager.onMotionChange { callback(LocationEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameMotionChange, token: token)
        }
    }

    @discardableResult
    public func onHttp(_ callback: @escaping (HttpEvent) -> Void) -> EventSubscription {
        let token = manager.onHttp { callback(HttpEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameHttp, token: token)
        }
    }

    @discardableResult
    public func onGeofence(_ callback: @escaping (GeofenceEvent) -> Void) -> EventSubscription {
        let token = manager.onGeofence { callback(GeofenceEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameGeofence, token: token)
        }
    }

    @discardableResult
    public func onHeartbeat(_ callback: @escaping (HeartbeatEvent) -> Void) -> EventSubscription {
        let token = manager.onHeartbeat { callback(HeartbeatEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameHeartbeat, token: token)
        }
    }

    @discardableResult
    public func onActivityChange(_ callback: @escaping (ActivityChangeEvent) -> Void) -> EventSubscription {
        let token = manager.onActivityChange { callback(ActivityChangeEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameActivityChange, token: token)
        }
    }

    @discardableResult
    public func onProviderChange(_ callback: @escaping (ProviderChangeEvent) -> Void) -> EventSubscription {
        let token = manager.onProviderChange { callback(ProviderChangeEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameProviderChange, token: token)
        }
    }

    @discardableResult
    public func onGeofencesChange(_ callback: @escaping (GeofencesChangeEvent) -> Void) -> EventSubscription {
        let token = manager.onGeofencesChange { callback(GeofencesChangeEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameGeofencesChange, token: token)
        }
    }

    @discardableResult
    public func onSchedule(_ callback: @escaping (ScheduleEvent) -> Void) -> EventSubscription {
        let token = manager.onSchedule { callback(ScheduleEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameSchedule, token: token)
        }
    }

    @discardableResult
    public func onPowerSaveChange(_ callback: @escaping (PowerSaveChangeEvent) -> Void) -> EventSubscription {
        let token = manager.onPowerSaveChange { callback(PowerSaveChangeEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNamePowerSaveChange, token: token)
        }
    }

    @discardableResult
    public func onConnectivityChange(_ callback: @escaping (ConnectivityChangeEvent) -> Void) -> EventSubscription {
        let token = manager.onConnectivityChange { callback(ConnectivityChangeEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameConnectivityChange, token: token)
        }
    }

    @discardableResult
    public func onEnabledChange(_ callback: @escaping (EnabledChangeEvent) -> Void) -> EventSubscription {
        let token = manager.onEnabledChange { callback(EnabledChangeEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameEnabledChange, token: token)
        }
    }

    @discardableResult
    public func onAuthorization(_ callback: @escaping (AuthorizationEvent) -> Void) -> EventSubscription {
        let token = manager.onAuthorization { callback(AuthorizationEvent($0)) }
        return EventSubscription { [weak self] in
            self?.manager.removeListener(TSEventNameAuthorization, token: token)
        }
    }

    /// Remove all event listeners registered via the `onX` methods.
    ///
    /// > Note: Any outstanding `EventSubscription` objects become inert after this call.
    public func removeListeners() {
        manager.removeListeners()
    }
}
