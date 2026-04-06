//
//  LocationManagerModel.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2025-08-09.
//  Copyright © 2025 Christopher Scott.
//

import Foundation
import Combine
import TSLocationManager
import CoreLocation
import MapKit
import SwiftUI

// MARK: - Small value types

struct TrackPoint: Identifiable, Equatable {
    let id = UUID()
    let coord: CLLocationCoordinate2D
    let heading: CLLocationDirection?

    static func == (lhs: TrackPoint, rhs: TrackPoint) -> Bool {
        lhs.coord.latitude  == rhs.coord.latitude &&
        lhs.coord.longitude == rhs.coord.longitude &&
        lhs.heading == rhs.heading
    }
}

// MARK: - Geofence overlays for the map

enum GeofenceOverlay: Identifiable {
    case circle(id: String, center: CLLocationCoordinate2D, radius: CLLocationDistance, color: Color = .green)
    case polygon(id: String, vertices: [CLLocationCoordinate2D], mecCenter: CLLocationCoordinate2D, mecRadius: CLLocationDistance, color: Color = .blue)

    var id: String {
        switch self {
        case .circle(let id, _, _, _):  return id
        case .polygon(let id, _, _, _, _): return id
        }
    }
}

struct GeofenceHit: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let action: String                // "ENTER" | "EXIT" | "DWELL"
    let center: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let trigger: CLLocationCoordinate2D
    let course: CLLocationDirection?
    
    // Small marker on the circumference where the ray hits.
    var edge: CLLocationCoordinate2D {
        Geospatial.projectToCircleEdge(center: center, to: trigger, radius: radius)
    }
    /// Segment to draw: from the HIT to the circumference.
    var segment: [CLLocationCoordinate2D] { [trigger, edge] }
}


// MARK: - Tiny helpers

@MainActor
func jsonString(from dict: [AnyHashable: Any]) -> String {
    guard JSONSerialization.isValidJSONObject(dict) else { return "{}" }
    do {
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted])
        return String(data: data, encoding: .utf8) ?? "{}"
    } catch {
        print("Error serializing JSON:", error)
        return "{}"
    }
}

// MARK: - ViewModel
@MainActor
final class LocationManagerModel: ObservableObject {
    @Published var watchId: Int? = nil
    @Published var geofenceOverlays: [String: GeofenceOverlay] = [:]
    // Map state
    @Published var points: [TrackPoint] = []                        // breadcrumbs
    @Published var stopPoints: [CLLocationCoordinate2D] = []
    @Published var lastFix: CLLocation?                             // latest location
    @Published var track: [CLLocationCoordinate2D] = []             // polyline coords
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // UI state
    @Published var isEnabled: Bool = false
    @Published var isMoving: Bool = false
    @Published var odometer: Double = 0.0
    @Published var odometerError: Double = 0.0

    // Geofence Hits
    @Published var geofenceHits: [GeofenceHit] = []
    @Published var geofenceHitVersion: Int = 0   // <— add this
    
    // Follow Location
    @Published var followsLocation: Bool = false
    @Published var suppressUnfollowUntil: Date? = nil
    
    // Red stationaryRadius Circle
    @Published var stationaryCenter: CLLocationCoordinate2D? = nil
    // Green polylines from last stationary center to motion-change location
    @Published var breakoutSegments: [[CLLocationCoordinate2D]] = []
        
    @Published var toastMessage: String? = nil
    @MainActor
    func toast(_ message: String) {
        print("ℹ️ \(message)")
        toastMessage = message
    }

    
    // SDK
    private let bgGeo = BackgroundGeolocation.sharedInstance()
    private let bgGeoNew = BGGeo.shared
    private var config: BGGeo.Config { bgGeoNew.config }
    private var cancellables = Set<BGGeo.EventSubscription>()
    
    // Tracker Host: (prod: https://tracker.transistorsoft.com)
    private let trackerHost = "https://bg-console-staging.herokuapp.com"

    // MARK: - Init

    init() {
        wireSDKCallbacks()
        bootstrapConfig()

        //BGGeo.TransistorAuthorizationService.destroyToken(url: "https://tracker.transistorsoft.com")
    }

    // MARK: - Wiring

    private func wireSDKCallbacks() {
        bgGeoNew.onProviderChange { event in
            print("[Swift][providerchange] status: \(event.status.rawValue), gps: \(event.gps), network: \(event.network)")
        }.store(in: &cancellables)

        bgGeoNew.onGeofence { event in
            print("[Swift][geofence] \(event.action) \(event.identifier)")
            guard let trigger = event.triggerCoordinate else { return }
            self.recordGeofenceHit(action: event.action, center: event.geofence.center, radius: event.geofence.radius, trigger: trigger, course: event.triggerHeading)
        }.store(in: &cancellables)

        bgGeoNew.onGeofencesChange { event in
            print("[Swift][geofenceschange] on: \(event.on.count), off: \(event.off.count)")

            if event.on.isEmpty && event.off.isEmpty {
                self.geofenceOverlays.removeAll()
                return
            }

            event.off.forEach { self.geofenceOverlays.removeValue(forKey: $0) }

            for gf in event.on {
                if gf.isPolygon, let coords = gf.coordinates, !coords.isEmpty {
                    self.geofenceOverlays[gf.identifier] = .polygon(id: gf.identifier, vertices: coords, mecCenter: gf.center, mecRadius: gf.radius, color: .blue)
                } else {
                    self.geofenceOverlays[gf.identifier] = .circle(id: gf.identifier, center: gf.center, radius: gf.radius, color: .green)
                }
            }
        }.store(in: &cancellables)

        bgGeoNew.onLocation { event in
            let fix = event.location

            if let odo = event.odometer {
                self.odometer = odo
            }
            if let err = event.odometerError {
                self.odometerError = err
            }
            print("[Swift][location] sample: \(event.sample), isMoving: \(event.isMoving), odometer: \(self.odometer) ± \(event.odometerError ?? 0)")
            if event.sample { return }

            let course = fix.course >= 0 ? fix.course : nil
            self.points.append(TrackPoint(coord: fix.coordinate, heading: course))
            if self.points.count > 1000 { self.points.removeFirst(self.points.count - 1000) }

            self.track.append(fix.coordinate)
            if self.track.count > 2000 { self.track.removeFirst(self.track.count - 2000) }

            if self.followsLocation { self.follow(fix) }
            self.lastFix = fix
        }.store(in: &cancellables)

        bgGeoNew.onMotionChange { event in
            let location = event.location
            NSLog("[Swift][motionchange] %d", event.isMoving)
            self.isMoving = event.isMoving
            self.followsLocation = true
            self.follow(location)

            if event.isMoving {
                if let c = self.stationaryCenter {
                    self.stopPoints.append(c)
                    if self.stopPoints.count > 200 {
                        self.stopPoints.removeFirst(self.stopPoints.count - 200)
                    }
                    self.breakoutSegments.append([c, location.coordinate])
                }
                self.stationaryCenter = nil
            } else {
                self.stationaryCenter = location.coordinate
            }
        }.store(in: &cancellables)

        bgGeoNew.onEnabledChange { event in
            print("[Swift][enabledchange] \(event.enabled)")
            self.isEnabled = event.enabled
            if self.isEnabled {
                self.followsLocation = true
            }
        }.store(in: &cancellables)
    }
    
    private func bootstrapConfig() {

        let org = UserDefaults.standard.string(forKey: "tracker.transistorsoft.com:org") ?? "_transistor-native"
        let username = UserDefaults.standard.string(forKey: "tracker.transistorsoft.com:username") ?? "iphone17"

        Task {
            do {
                let token = try await BGGeo.TransistorAuthorizationService.findOrCreateToken(
                    org: org,
                    username: username,
                    url: trackerHost
                )

                // reset: false → config closure only runs on first install.
                // Subsequent launches use persisted config from SettingsSheet.
                // transistorAuthorizationToken always applies (even on subsequent launches).
                bgGeoNew.ready(reset: false, transistorAuthorizationToken: token) { config in
                    config.geolocation.distanceFilter = 50
                    config.http.autoSync = false
                    config.persistence.extras = ["config-extra": "CONFIG"]
                    config.persistence.maxRecordsToPersist = -1
                    config.persistence.maxDaysToPersist = 7
                    config.persistence.persistMode = .all
                    config.geolocation.filter.burstWindow = 0.5
                    config.geolocation.filter.policy = .conservative
                    config.geolocation.filter.maxBurstDistance = 1000
                    config.geolocation.filter.maxImpliedSpeed = 100
                    config.geolocation.locationAuthorizationRequest = .always
                    config.geolocation.disableLocationAuthorizationAlert = false
                    config.geolocation.desiredAccuracy = kCLLocationAccuracyBest
                    config.logger.debug = true
                    config.logger.logLevel = .verbose
                    config.logger.logMaxDays = 7
                    config.app.preventSuspend = true
                    config.app.heartbeatInterval = 60
                    config.app.stopOnTerminate = false
                    config.app.startOnBoot = true
                }

                NSLog("[token] ✅ org=\(org) username=\(username) \(token.toDictionary())")
            } catch {
                NSLog("[token] ❌ \(error.localizedDescription)")
            }
        }

        isEnabled = bgGeoNew.state.enabled
        isMoving = bgGeoNew.state.isMoving
    }
    
    
    // MARK: - Controls

    func toggleEnabled() {
        if isEnabled {
            bgGeoNew.stop()
            points.removeAll()
            stopPoints.removeAll()
            track.removeAll()
            geofenceHits.removeAll()
            breakoutSegments.removeAll()
            stationaryCenter = nil
        } else {
            Task {
                do {
                    if bgGeoNew.state.trackingMode == .location {
                        try await bgGeoNew.start()
                    } else {
                        try await bgGeoNew.startGeofences()
                    }
                } catch {
                    NSLog("[BGGeo] start failed: \(error)")
                }
            }
        }
        isEnabled = !isEnabled
    }

    func changePace() {
        guard bgGeoNew.state.enabled else { return }
        bgGeoNew.changePace(!bgGeoNew.state.isMoving)
        isMoving = bgGeoNew.state.isMoving
    }
    
    func getLocationCount() -> Int {
        return bgGeoNew.store.count
    }
    
    func sync() {
        Task {
            do {
                _ = try await bgGeoNew.store.sync()
                Sound.play(.messageSent)
                Sound.haptic(.medium)
            } catch {
                print("**** sync failure: \(error) *****")
                Sound.play(.error)
                Sound.haptic(.heavy)
            }
        }
    }
    func setConfig() {
        config.edit { config in
            config.geolocation.distanceFilter = 50
            config.http.autoSync = false
            config.logger.debug = true
        }
    }

    func getCurrentPosition() {
        Task {
            do {
                let event = try await bgGeoNew.getCurrentPosition(
                    timeout: 10,
                    desiredAccuracy: 10,
                    maximumAge: 5000,
                    samples: 3,
                    persist: true,
                    extras: ["getCurrentPosition": true]
                )
                NSLog("[Swift][getCurrentPosition] SUCCESS: \(event.coords?.latitude ?? 0), \(event.coords?.longitude ?? 0)")
                self.followsLocation = true
                self.follow(event.location)
            } catch {
                print("[Swift][getCurrentPosition] ERROR: \(error)")
            }
        }
    }

    /// Start watching position using TSWatchPositionRequest
    func watchPosition() {
        if let watchId = self.watchId {
            bgGeoNew.stopWatchPosition(watchId)
            self.watchId = nil
            return
        }
        self.watchId = bgGeoNew.watchPosition(
            interval: 1000,
            timeout: 60,
            persist: false,
            extras: ["watchPosition": true],
            success: { [weak self] event in
                guard let self else { return }
                NSLog("[Swift][watchPosition] SUCCESS: \(event.location)")
                self.followsLocation = true
                self.follow(event.location)
            },
            failure: { error in
                print("[Swift][watchPosition] ERROR: \(error)")
            }
        )
    }
        
    func resetOdometer() {
        Task {
            do {
                let event = try await bgGeoNew.setOdometer(0.0,
                    desiredAccuracy: kCLLocationAccuracyBest,
                    maximumAge: 5000,
                    samples: 3,
                    extras: ["resetOdometer": true]
                )
                NSLog("[Swift][resetOdometer] SUCCESS: \(event.odometer ?? 0)")
            } catch {
                print("[Swift][resetOdometer] ERROR: \(error)")
            }
        }
    }
    
    func reset() {
        config.reset()
        bgGeoNew.stop()
        Task { try? await bgGeoNew.start() }
        isEnabled = bgGeoNew.state.enabled
        isMoving  = bgGeoNew.state.isMoving

        // Optional: clear trail
        points.removeAll()
        track.removeAll()
    }
    
    // LocationManagerModel.swift
    func removeAllGeofences() {
        Task {
            try? await bgGeoNew.geofences.removeAll()
            Sound.play(.messageSent)
            Sound.haptic(.medium)
        }
    }
    
    func requestPermission(with authRequest: BGGeo.LocationAuthorizationRequest) {
        config.edit { config in
            config.geolocation.locationAuthorizationRequest = authRequest
        }
        Task {
            do {
                let status = try await bgGeoNew.authorization.requestPermission()
                self.toast("Status: \(status)")
                print("[requestPermission] status: \(status)")
            } catch {
                self.toast("Failed: \(error)")
                print("[requestPermission] FAILURE: \(error)")
            }
        }
    }

    func getProviderState() -> BGGeo.ProviderChangeEvent {
        bgGeoNew.authorization.getState()
    }

    func destroyLocations() {
        Task {
            do {
                try await bgGeoNew.store.destroyAll()
                Sound.play(.messageSent)
                Sound.haptic(.medium)
            } catch {
                Sound.play(.error)
                Sound.haptic(.heavy)
            }
        }
    }
    
    func emailLog(to address: String) {
        Task {
            do {
                try await bgGeoNew.logger.emailLog(to: address)
            } catch {
                Sound.play(.error)
                Sound.haptic(.heavy)
            }
        }
    }
    
    @MainActor
    func registerDemoServer(organization: String, username: String) async {
        do {
            // (optional) destroy any existing token first
            BGGeo.TransistorAuthorizationService.destroyToken(url: trackerHost)

            UserDefaults.standard.set(organization, forKey: "tracker.transistorsoft.com:org")
            UserDefaults.standard.set(username,    forKey: "tracker.transistorsoft.com:username")

            let token = try await BGGeo.TransistorAuthorizationService.findOrCreateToken(
                org: organization,
                username: username,
                url: trackerHost
            )
            
            NSLog("[registerDemoServer] ✅ Got token '\(token.accessToken)', apiUrl: \(token.apiUrl)")
            
            self.config.edit { config in
                config.http.url = token.apiUrl
                config.authorization.update(with: token.toDictionary())
            }
            
            
            Sound.play(.messageSent)
            Sound.haptic(.medium)
        } catch {
            Sound.play(.error)
            Sound.haptic(.heavy)
        }
    }
    
    func destroyLog() {
        Task { try? await bgGeoNew.logger.destroyLog() }
        Sound.play(.messageSent)
        Sound.haptic(.medium)
    }
    // MARK: - Geofences (called by MapView form)

    /// Circular geofence
    func addCircularGeofence(at coordinate: CLLocationCoordinate2D,
                             radius: Double,
                             notifyOnEntry: Bool,
                             notifyOnExit: Bool,
                             notifyOnDwell: Bool,
                             loiteringDelayMs: Int,
                             extras: NSDictionary,
                             identifier: String) {

        let gf = BGGeo.Geofence(
            identifier: identifier,
            radius: radius,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            notifyOnEntry: notifyOnEntry,
            notifyOnExit: notifyOnExit,
            notifyOnDwell: notifyOnDwell,
            loiteringDelay: NSNumber(value: loiteringDelayMs).doubleValue,
            extras: ["geofence-extra": "bar"]
        )

        Task {
            do {
                try await bgGeoNew.geofences.add(gf)
                NSLog("[Geofence] ✅ Added circular '\(identifier)'")
                self.toast("Geofence added")
            } catch {
                NSLog("[Geofence] ❌ Add circular failed: \(error)")
                self.toast("Add failed")
            }
        }
    }
    
    func recordGeofenceHit(action: String,
                           center: CLLocationCoordinate2D,
                           radius: CLLocationDistance,
                           trigger: CLLocationCoordinate2D,
                           course: CLLocationDirection?) {
        
        DispatchQueue.main.async {
            self.geofenceHits.append(
                GeofenceHit(action: action, center: center, radius: radius, trigger: trigger, course: course)
            )
            if self.geofenceHits.count > 200 {
                self.geofenceHits.removeFirst(self.geofenceHits.count - 200)
            }
            self.geofenceHitVersion &+= 1   // <— bump version to force layer refresh
        }
        print("[Swift][recordGeofenceHit] \(action), center: [\(center.latitude),\(center.longitude)], trigger: [\(trigger.latitude),\(trigger.longitude)]")
        
        
    }
    
    /// Polygon geofence (SDK handles MEC internally)
    func addPolygonGeofence(vertices: [CLLocationCoordinate2D],
                            notifyOnEntry: Bool,
                            notifyOnExit: Bool,
                            notifyOnDwell: Bool,
                            loiteringDelayMs: Int,
                            extras: NSDictionary,
                            identifier: String) {

        guard vertices.count >= 3 else {
            toast("Need 3+ points")
            return
        }
        
        NSLog("📝 addPolygonGeofence called with \(vertices.count) vertices")
        
        let gf = BGGeo.Geofence(
            identifier: identifier,
            vertices: vertices.map { [$0.latitude, $0.longitude] },
            notifyOnEntry: notifyOnEntry,
            notifyOnExit: notifyOnExit,
            notifyOnDwell: notifyOnDwell,
            loiteringDelay: NSNumber(value: loiteringDelayMs).doubleValue,
            extras: ["FOO": "BAR"]
        )

        Task {
            do {
                try await bgGeoNew.geofences.add(gf)
                NSLog("[Geofence] ✅ Added polygon '\(identifier)' (\(vertices.count) pts)")
                self.toast("Geofence added")
            } catch {
                NSLog("[Geofence] ❌ Add polygon failed: \(error)")
                self.toast("Add failed")
            }
        }
    }

    // MARK: - Map follow

    private func follow(_ loc: CLLocation) {
        // Suppress "unfollow" caused by the programmatic camera move that follows
        suppressUnfollowUntil = Date().addingTimeInterval(0.75)

        let center = loc.coordinate
        func metersToDegrees(_ m: CLLocationDistance) -> CLLocationDegrees { m / 111_000.0 }
        let spanDeg = metersToDegrees(500)
        region = MKCoordinateRegion(center: center,
                                    span: MKCoordinateSpan(latitudeDelta: spanDeg, longitudeDelta: spanDeg))
    }

    // MARK: - UI nicety
    
}


