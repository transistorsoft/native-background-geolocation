import SwiftUI
import BackgroundGeolocation
import CoreLocation
import UIKit

struct SettingsSheet: View {
    @ObservedObject var model: LocationManagerModel
    @Environment(\.dismiss) private var dismiss

    // MARK: Current values (pre-filled from TSConfig on appear)
    @State private var trackingModeIsFull = true                    // true: start(); false: startGeofences()
    @State private var initialTrackingModeIsFull = true   // snapshot from config
    @State private var locationAuthorizationRequest: BGGeo.LocationAuthorizationRequest = .always
    @State private var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    @State private var distanceFilter: Int = 50
    @State private var geofenceProximityRadius: Int = 1000
    @State private var useSignificantChangesOnly = false
    @State private var disableElasticity: Bool = false
    @State private var stopTimeout: Int = 1
    @State private var stopDetectionDelayMs: Int = 0
    @State private var disableMotionActivityUpdates: Bool = false
    @State private var disableStopDetection: Bool = false
    @State private var url: String = ""
    @State private var autoSync = true
    @State private var autoSyncThreshold: Int = 0
    @State private var batchSync = false
    @State private var maxBatchSize: Int = -1
    @State private var maxRecordsToPersist: Int = -1
    @State private var maxDaysToPersist: Int = -1
    @State private var persistMode: BGGeo.PersistMode = .all // ALL
    @State private var stopOnTerminate = true
    @State private var startOnBoot = false
    @State private var heartbeatInterval: Int = 60
    @State private var debug = true
    @State private var logLevel: BGGeo.LogLevel = .verbose
    @State private var logMaxDays: Int = 3
    @State private var preventSuspend = false                       // iOS-only
    @State private var isScheduleSheetPresented = false
    @State private var onMinutes: Int = 1                    // length of schedule period (ON)
    @State private var offMinutes: Int = 1                  // time between periods (OFF)
    @State private var applyToSDK: Bool = true
    @State private var generatedSchedulePreview: [String] = []
    @State private var clearSchedule: Bool = false
    // MARK: Location Filter state
    @State private var filterPolicy: BGGeo.LocationFilterPolicy = .conservative
    @State private var filterUseKalman: Bool = true
    @State private var kalmanProfile: BGGeo.KalmanProfile = .default
    @State private var maxImpliedSpeed: Double = 60
    @State private var maxBurstDistance: Double = 300
    @State private var burstWindow: Double = 10
    @State private var rollingWindow: Int = 5
    @State private var odometerUseKalman: Bool = true
    @State private var filterDebug: Bool = false
    @State private var kalmanDebug: Bool = false
    // Mark tracker.transistorsoft.com registration
    @State private var isTrackerAuthPresented: Bool = false
    @State private var trackerOrg: String = UserDefaults.standard.string(forKey: "tracker.transistorsoft.com:org") ?? ""
    @State private var trackerUsername: String = UserDefaults.standard.string(forKey: "tracker.transistorsoft.com:username") ?? ""
    
    var body: some View {
        NavigationStack {
            Form {
                HStack(alignment: .center) {
                    Text("Settings")
                        .font(.largeTitle).bold()
                    Spacer()
                    Menu {
                        Button("Reset Odometer") { model.resetOdometer() }
                        Button("Email Log") {
                            model.emailLog(to: UserDefaults.standard.string(forKey: "EmailLogAddress") ?? "")
                        }
                        Button("Sync") { model.sync() }
                        // TODO: re-wire once AllEventsSmokeTest is rewritten in Swift Testing
                        // Button("Run Smoke Test") {
                        //     AllEventsSmokeTest.run(withTimeout: 60.0)
                        // }
                        Button("Tracker Auth") {
                            isTrackerAuthPresented = true
                        }
                        
                        Button("Generate Schedule") { isScheduleSheetPresented = true }
                        Button("Remove Geofences") { model.removeAllGeofences() }
                        Button("Destroy Locations", role: .destructive) { model.destroyLocations() }
                        Button("Destroy Log", role: .destructive) { model.destroyLog() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.accentColor)
                    }
                }
                  .padding(.vertical, 2)
                  .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                  .listRowBackground(Color.clear)
                  .alert("Demo Server Registration", isPresented: $isTrackerAuthPresented) {
                      TextField("Organization name", text: $trackerOrg)
                      TextField("Username", text: $trackerUsername)
                      Button("Register") {
                          Task { @MainActor in
                              await model.registerDemoServer(organization: trackerOrg, username: trackerUsername)
                          }
                      }
                      Button("Cancel", role: .cancel) {}
                  } message: {
                      Text("Register this device with the demo server.")
                  }
                
                // MARK: Geolocation
                Section("Geolocation") {
                    Picker("Tracking mode", selection: $trackingModeIsFull) {
                        Text("Location + Geofences").tag(true)
                        Text("Geofences only").tag(false)
                    }

                    Picker("Authorization", selection: $locationAuthorizationRequest) {
                        Text("Always").tag(BGGeo.LocationAuthorizationRequest.always)
                        Text("WhenInUse").tag(BGGeo.LocationAuthorizationRequest.whenInUse)
                        Text("Any").tag(BGGeo.LocationAuthorizationRequest.any)
                    }

                    Picker("Desired accuracy", selection: Binding(
                        get: { desiredAccuracy },
                        set: { desiredAccuracy = $0 }
                    )) {
                        Text("NAVIGATION").tag(kCLLocationAccuracyBestForNavigation)
                        Text("HIGH").tag(kCLLocationAccuracyBest)
                        Text("MEDIUM").tag(10.0)
                        Text("LOW").tag(100.0)
                        Text("MINIMUM").tag(1000.0)
                    }

                    Stepper("Distance filter: \(distanceFilter) m", value: $distanceFilter,
                            in: 0...1000, step: 10)
                    
                    Stepper("Stop timeout: \(stopTimeout) min",
                            value: $stopTimeout,
                            in: 0...30, step: 1)
                    
                    Stepper("Geofence proximity radius: \(geofenceProximityRadius) m",
                            value: $geofenceProximityRadius, in: 100...100000, step: 100)

                    Toggle("Use significant-changes only", isOn: $useSignificantChangesOnly)
                    Toggle("Disable elasticity (no DF auto-scale)", isOn: $disableElasticity)
                }
                
                // MARK: Location Filter
                Section("Location Filter") {
                    // Policy
                    Picker("Policy", selection: $filterPolicy) {
                        Text("Pass-Through").tag(BGGeo.LocationFilterPolicy.passThrough)
                        Text("Adjust").tag(BGGeo.LocationFilterPolicy.adjust)
                        Text("Conservative").tag(BGGeo.LocationFilterPolicy.conservative)
                    }
                    .pickerStyle(.segmented)

                    // Kalman controls
                    Toggle("Use Kalman (per-step)", isOn: $filterUseKalman)

                    // Kalman profile
                    Picker("Kalman profile", selection: $kalmanProfile) {
                        Text("Default").tag(BGGeo.KalmanProfile.default)
                        Text("Aggressive").tag(BGGeo.KalmanProfile.aggressive)
                        Text("Conservative").tag(BGGeo.KalmanProfile.conservative)
                    }

                    // Essentials
                    Stepper("Max implied speed: \(Int(maxImpliedSpeed)) m/s",
                            value: $maxImpliedSpeed, in: 1...200, step: 10)

                    // Advanced
                    Group {
                        Stepper("Max burst distance: \(Int(maxBurstDistance)) m",
                                value: $maxBurstDistance, in: 5...2000, step: 100)
                        Stepper("Burst window: \(Int(burstWindow)) s",
                                value: $burstWindow, in: 1...120, step: 1)
                        Stepper("Rolling window: \(rollingWindow)",
                                value: $rollingWindow, in: 3...20, step: 1)

                        Toggle("Odometer uses Kalman", isOn: $odometerUseKalman)

                        Toggle("Filter debug", isOn: $filterDebug)
                        Toggle("Kalman debug", isOn: $kalmanDebug)
                    }
                }
                
                // MARK: Motion Detection
                Section("Motion Detection") {
                    // New: stopDetectionDelay (milliseconds)
                    Stepper("Stop detection delay: \(stopDetectionDelayMs) ms",
                            value: $stopDetectionDelayMs,
                            in: 0...600_000, step: 1_000)

                    // New: disableMotionActivityUpdates
                    Toggle("Disable motion-activity updates", isOn: $disableMotionActivityUpdates)

                    // New: disableStopDetection
                    Toggle("Disable stop detection", isOn: $disableStopDetection)

                    Toggle("Prevent suspend (iOS)", isOn: $preventSuspend)
                }

                // MARK: HTTP & Persistence
                Section("HTTP & Persistence") {
                    TextField("URL", text: $url).textInputAutocapitalization(.never)
                    Toggle("Auto-sync", isOn: $autoSync)
                    Picker("Auto-sync threshold", selection: $autoSyncThreshold) {
                        ForEach([0,5,10,25,50,100], id: \.self) { Text("\($0)").tag($0) }
                    }
                    Toggle("Batch sync", isOn: $batchSync)
                    Picker("Max batch size", selection: $maxBatchSize) {
                        ForEach([-1,5,10,50,100], id: \.self) { Text("\($0)").tag($0) }
                    }
                    Picker("Max records", selection: $maxRecordsToPersist) {
                        ForEach([-1,0,1,3,10,100], id: \.self) { Text("\($0)").tag($0) }
                    }
                    Picker("Max days", selection: $maxDaysToPersist) {
                        ForEach([-1,1,2,3,5,7,14], id: \.self) { Text("\($0)").tag($0) }
                    }
                    Picker("Persist mode", selection: $persistMode) {
                        Text("ALL").tag(BGGeo.PersistMode.all)
                        Text("LOCATIONS").tag(BGGeo.PersistMode.location)
                        Text("GEOFENCES").tag(BGGeo.PersistMode.geofence)
                        Text("NONE").tag(BGGeo.PersistMode.none)
                    }
                }

                // MARK: Application
                Section("Application") {
                    Toggle("Stop on terminate", isOn: $stopOnTerminate)
                    Toggle("Start on boot", isOn: $startOnBoot)
                    Picker("Heartbeat interval", selection: $heartbeatInterval) {
                        ForEach([-1,60,120,300,900], id: \.self) { Text("\($0)").tag($0) }
                    }
                }

                // MARK: Debug
                Section("Debug") {
                    Toggle("Debug", isOn: $debug)
                    Picker("Log level", selection: $logLevel) {
                        Text("OFF").tag(BGGeo.LogLevel.off)
                        Text("ERROR").tag(BGGeo.LogLevel.error)
                        Text("WARN").tag(BGGeo.LogLevel.warning)
                        Text("INFO").tag(BGGeo.LogLevel.info)
                        Text("DEBUG").tag(BGGeo.LogLevel.debug)
                        Text("VERBOSE").tag(BGGeo.LogLevel.verbose)
                    }
                    Picker("Log max days", selection: $logMaxDays) {
                        ForEach([1,2,3,4,5,6,7], id: \.self) { Text("\($0)").tag($0) }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        Sound.play(.close)
                        Sound.haptic(.medium)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: apply)
                }
            }
            .onAppear(perform: loadFromConfig)
            .sheet(isPresented: $isScheduleSheetPresented) {
                NavigationStack {
                    Form {
                        Section("Schedule Generator") {
                            Stepper("Period ON (minutes): \(onMinutes)", value: $onMinutes, in: 1...720)
                                .disabled(clearSchedule)
                            Stepper("Time between periods (OFF, minutes): \(offMinutes)", value: $offMinutes, in: 0...1440)
                                .disabled(clearSchedule)
                            Toggle("Apply to SDK now", isOn: $applyToSDK)
                            Toggle("Remove existing schedule", isOn: $clearSchedule)
                        }

                        if !clearSchedule && !generatedSchedulePreview.isEmpty {
                            Section("Preview (applies to days 1-7)") {
                                ForEach(generatedSchedulePreview, id: \.self) { line in
                                    Text(line).font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                    }
                    .navigationTitle("Generate Schedule")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { isScheduleSheetPresented = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Generate") {
                                let bg = BGGeo.shared
                                if clearSchedule {
                                    generatedSchedulePreview = []
                                    if applyToSDK {
                                        bg.stopSchedule()
                                        bg.config.edit { config in
                                            config.app.schedule = []
                                        }
                                    }
                                    isScheduleSheetPresented = false
                                } else {
                                    generatedSchedulePreview = buildScheduleStrings()
                                    if applyToSDK {
                                        bg.config.edit { config in
                                            config.app.schedule = generatedSchedulePreview
                                        }
                                        bg.startSchedule()
                                    }
                                    isScheduleSheetPresented = false
                                }
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: Load current TSConfig into the sheet
    private func loadFromConfig() {
        let cfg = BGGeo.shared.config

        trackingModeIsFull = BGGeo.shared.state.trackingMode == .location
        locationAuthorizationRequest = cfg.geolocation.locationAuthorizationRequest
        desiredAccuracy = cfg.geolocation.desiredAccuracy
        distanceFilter = Int(cfg.geolocation.distanceFilter)
        geofenceProximityRadius = Int(cfg.geolocation.geofenceProximityRadius)
        useSignificantChangesOnly = cfg.geolocation.useSignificantChangesOnly
        stopTimeout = Int(cfg.geolocation.stopTimeout)
        disableElasticity = cfg.geolocation.disableElasticity

        stopDetectionDelayMs = Int(cfg.activity.stopDetectionDelay)
        disableMotionActivityUpdates = cfg.activity.disableMotionActivityUpdates
        disableStopDetection = cfg.activity.disableStopDetection

        url = cfg.http.url
        autoSync = cfg.http.autoSync
        autoSyncThreshold = cfg.http.autoSyncThreshold
        batchSync = cfg.http.batchSync
        maxBatchSize = cfg.http.maxBatchSize
        maxRecordsToPersist = cfg.persistence.maxRecordsToPersist
        maxDaysToPersist = cfg.persistence.maxDaysToPersist
        persistMode = cfg.persistence.persistMode

        stopOnTerminate = cfg.app.stopOnTerminate
        startOnBoot = cfg.app.startOnBoot
        heartbeatInterval = Int(cfg.app.heartbeatInterval)

        debug = cfg.logger.debug
        logLevel = cfg.logger.logLevel
        logMaxDays = cfg.logger.logMaxDays
        preventSuspend = cfg.app.preventSuspend

        let filter = cfg.geolocation.filter
        filterPolicy       = filter.policy
        filterUseKalman    = filter.useKalman
        kalmanProfile      = filter.kalmanProfile
        maxImpliedSpeed    = filter.maxImpliedSpeed
        maxBurstDistance   = filter.maxBurstDistance
        burstWindow        = filter.burstWindow
        rollingWindow      = filter.rollingWindow
        odometerUseKalman  = filter.odometerUseKalmanFilter
        filterDebug        = filter.filterDebug
        kalmanDebug        = filter.kalmanDebug
    }

    // MARK: Apply to TSConfig and optionally restart modes
    private func apply() {
        Sound.play(.close)
        Sound.haptic(.heavy)

        let bg = BGGeo.shared

        bg.config.edit { config in
            config.geolocation.locationAuthorizationRequest = locationAuthorizationRequest
            config.geolocation.desiredAccuracy = desiredAccuracy
            config.geolocation.distanceFilter = Double(distanceFilter)
            config.geolocation.geofenceProximityRadius = Double(geofenceProximityRadius)
            config.geolocation.useSignificantChangesOnly = useSignificantChangesOnly
            config.geolocation.disableElasticity = disableElasticity
            config.geolocation.stopTimeout = Double(stopTimeout)

            config.activity.stopDetectionDelay = Double(stopDetectionDelayMs)
            config.activity.disableMotionActivityUpdates = disableMotionActivityUpdates
            config.activity.disableStopDetection = disableStopDetection

            config.http.url = url
            config.http.autoSync = autoSync
            config.http.autoSyncThreshold = autoSyncThreshold
            config.http.batchSync = batchSync
            config.http.maxBatchSize = maxBatchSize
            config.persistence.maxRecordsToPersist = maxRecordsToPersist
            config.persistence.maxDaysToPersist = maxDaysToPersist
            config.persistence.persistMode = persistMode

            config.app.stopOnTerminate = stopOnTerminate
            config.app.startOnBoot = startOnBoot
            config.app.heartbeatInterval = Double(heartbeatInterval)

            config.logger.debug = debug
            config.logger.logLevel = logLevel
            config.logger.logMaxDays = logMaxDays
            config.app.preventSuspend = preventSuspend

            config.geolocation.filter.policy = filterPolicy
            config.geolocation.filter.kalmanProfile = kalmanProfile
            config.geolocation.filter.useKalman = filterUseKalman
            config.geolocation.filter.maxImpliedSpeed = maxImpliedSpeed
            config.geolocation.filter.maxBurstDistance = maxBurstDistance
            config.geolocation.filter.burstWindow = burstWindow
            config.geolocation.filter.rollingWindow = rollingWindow
            config.geolocation.filter.odometerUseKalmanFilter = odometerUseKalman
            config.geolocation.filter.filterDebug = filterDebug
            config.geolocation.filter.kalmanDebug = kalmanDebug
        }

        if trackingModeIsFull != initialTrackingModeIsFull {
            initialTrackingModeIsFull = trackingModeIsFull
            if bg.state.enabled {
                Task {
                    do {
                        if trackingModeIsFull {
                            try await bg.start()
                        } else {
                            try await bg.startGeofences()
                        }
                    } catch {
                        NSLog("[BGGeo] restart failed: \(error)")
                    }
                }
            }
        }
        dismiss()
    }

    private func buildScheduleStrings() -> [String] {
        var results: [String] = []
        let cal = Calendar.current
        let daySpec = "1-7"

        // Start at 00:00 of today; end at 23:59
        let now = Date()
        let startOfDay = cal.startOfDay(for: now)
        guard let endOfDay = cal.date(byAdding: .minute, value: 23*60 + 59, to: startOfDay) else { return results }

        let f = DateFormatter()
        f.dateFormat = "HH:mm"

        // Safety rails
        let on = max(1, onMinutes)
        let off = max(0, offMinutes)
        let cadence = on + off
        if cadence <= 0 { return results }

        var cursor = startOfDay
        while cursor <= endOfDay {
            // 1) OFF period first (implicit — we just advance the cursor)
            guard let afterOff = cal.date(byAdding: .minute, value: off, to: cursor) else { break }

            // 2) ON period next
            let onStart = afterOff
            if onStart > endOfDay { break }
            guard let tentativeOnEnd = cal.date(byAdding: .minute, value: on, to: onStart) else { break }
            let onEnd = min(tentativeOnEnd, endOfDay)

            let rec = "\(daySpec) \(f.string(from: onStart))-\(f.string(from: onEnd)) geofence"
            results.append(rec)

            if onEnd >= endOfDay { break }

            // Next cycle begins at end of ON
            cursor = onEnd
        }

        // Ensure the last item ends exactly at 23:59
        if let last = results.last {
            let parts = last.split(separator: " ")
            if parts.count == 2 {
                let times = parts[1].split(separator: "-")
                if times.count == 2 {
                    let start = String(times[0])
                    results[results.count - 1] = "\(daySpec) \(start)-23:59"
                }
            }
        }

        return results
    }

}
