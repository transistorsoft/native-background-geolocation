# CHANGELOG

## 4.7.2 &mdash; 2026-10-05
- fix(WO-107): creating a polygon geofence no longer writes two `NSLog` lines. The SDK logged each polygon's enclosing circle, whatever `logger.logLevel` said, and NSLog is synchronous: with thousands of polygons, part of the time `addGeofences` took (RN #2668)
- fix(WO-104): `stop()` now releases the location monitoring that an earlier run of the app left registered with iOS, which kept waking a stopped app. iOS keeps region, significant-location-change and visit monitoring registered after the app's process ends, and with `stopOnTerminate: false` terminating the app mid-tracking deliberately leaves the stationary region and significant-change monitoring registered so that iOS relaunches it. `stop()` released only what the current process had started, so in a relaunched app it left them in place: the stationary region kept relaunching the stopped app in the background until it fired, and leftover significant-change monitoring was never released at all. Leftover geofences stayed monitored too, and a geofence event that arrived while tracking was stopped was still delivered; it is now dropped and that geofence is no longer monitored. A `stop()` made before the SDK's own start after `ready()` (React Native and Cordova resolve `ready()` about 0.75 s earlier), or after a background relaunch had resumed tracking ahead of `ready()`, released nothing at all, and left location updates running in the second case. An app relaunched while moving now removes the old stationary region as soon as tracking resumes: left registered, it fired later as a stationary exit on a device already moving, giving a duplicate `motionchange` event or, with `triggerActivities` set, "Motion trigger denied" and tracking forced into the stationary state. A launch with tracking off releases what an earlier version left behind. Significant-change and visit monitoring are released only when the SDK registered them, so monitoring that the app itself or another SDK started is left alone; the one exception is the first launch after upgrading from an earlier version, which cannot tell. While the scheduler is enabled, `stop()` leaves significant-change monitoring to it, since a significant-change wake is how a stop-period re-evaluates the schedule. Reported in react-native #2666 (WO-104)
- fix(ios): `preventSuspend` no longer stops a few minutes into the background. The SDK renews its background time with a timer that fired with 5 s of that time left, which is when iOS calls a background task's expiration handler (measured on iOS 26). When the handler ran first, the log showed `FORCE KILL BACKGROUND TASK`: the handler ended the SDK's prevent-suspend task and stopped the timer, and nothing restarted them while the device stayed stationary. iOS then suspended the app, and `onHeartbeat` stopped until the app was next opened. The timer now fires with 10 s left, as it did in TSLocationManager 3.x, the 4.x plugins (cordova #2439)
- fix(WO-079): `persistence.maxRecordsToPersist`, `persistence.maxDaysToPersist` or `persistence.persistMode` set to a string that is not a whole number, e.g. `"c4"` or `"10m"`, now takes the setting's default, as on Android. iOS read such a string as `0`: `maxRecordsToPersist` 0 **deleted every stored location**, `maxDaysToPersist` 0 purged every record, and `persistMode` 0 is `None`, so the SDK silently stopped persisting. The defaults are `-1` (no limit), `1` day and `All`. A string holding a whole number, e.g. `"5000"`, still works. The typed APIs cannot send such a value; a JavaScript app can, for example from a text field or a remote configuration (long-standing)

## 4.7.1 &mdash; 2026-09-27
- docs(swift): the `BGGeo.ready(transistorAuthorizationToken:)` example now compiles. It calls `BGGeo.TransistorAuthorizationService.findOrCreateToken` by its full name and passes the `url` it requires, `https://tracker.transistorsoft.com`
- fix(WO-066): a `setConfig` whose only change was `authorization.accessToken` or `authorization.refreshToken` is now saved at once. The SDK compared the old and new configuration with both tokens masked down to their first five characters, which every JWT shares (`eyJhb`), so it saw no change and saved nothing. The new token was used, but reached storage only when the app next went to the background. If the app was killed before then (a crash, or a system kill while suspended), a relaunch with `reset: false` used the previous token. The same applied to a token-only `setConfig` sent in an HTTP response (WO-066)
- fix(WO-060): a `geolocation.locationAuthorizationAlert` that leaves out any of its five strings (`titleWhenOff`, `titleWhenNotEnabled`, `instructions`, `cancelButton`, `settingsButton`) now takes the SDK's default for each one missing. The dictionary was stored exactly as given. Without an `instructions` string, the app could crash with `NSInvalidArgumentException` when the SDK showed its Settings alert. The SDK shows that alert when the app lacks the permission `locationAuthorizationRequest` asks for, for example on each return to the foreground while tracking with `Always` requested and only When In Use granted. A missing title or button reached the alert as nil. A value that is not a string, such as a JSON `null`, also takes its key's default, with a warning in the log. The State now reports all five strings. A dictionary still replaces the previous one whole, so a key it leaves out takes its default, not the value an earlier call set. Keys outside the five are kept as given. A dictionary saved by an earlier release is completed on the next launch (WO-060)
- fix(WO-050): `activity.triggerActivities` now accepts the array form that the API declares and documents, e.g. `["in_vehicle", "on_foot"]`. iOS refused an array: the setting kept its previous value (by default, no filter) and only a warning in the SDK log said so. The array is now stored as the comma-separated string the SDK has always used, `"in_vehicle,on_foot"`, and the State reports that string, as on Android. Elements that are not strings are ignored (WO-050)
- fix(ios): `setConfig`, `ready` or `reset` crashed the app when the configuration held `null` for a state key: `enabled`, `isMoving`, `trackingMode`, `schedulerEnabled` or `includeDeprecatedPropertiesInDictionary`. A dictionary or array for one of those keys crashed the same way. No `try`/`catch` around the call could stop it. A `null` for a state key is now ignored, as it already was for every other configuration key. A value that is not a number, boolean or string is ignored with a warning in the log
- fix(WO-043): the scheduler now runs only on the main thread. It was driven from the main thread, from the configuration's event queue, and from whichever thread called `startSchedule()`, `stopSchedule()` or `getCurrentPosition()` (React Native's and Capacitor's module queues, Swift callers, remote commands), and nothing kept those threads apart. When a window's end was noticed off the main thread, stopping tracking waited on the main thread, and the main thread could start the next window during that wait: the stop then tore down the tracking the start had just set up, and `onSchedule` delivered the start before the stop. Two threads could also fire the same transition twice, or read the schedule while a configuration change was replacing it. Called off the main thread, `startSchedule()`, `stopSchedule()` and `ready()` now return before they take effect, in call order; read the State back on the main thread (in Swift, on the main actor). The React Native, Cordova and Flutter plugins already call them on the main thread; Capacitor does from its release that carries WO-043. A configuration that re-applies the schedule a running scheduler already holds no longer re-reads it, which could fire the open window's start a second time (WO-043)
- fix(WO-044): the scheduler could crash with a stack overflow while checking the schedule. After finding the current window it also computed the next schedule edge. When that edge had already passed, it searched again with the same time, got the same answer, and repeated until the stack ran out. Two cases reached it. A window could close during the check itself: starting tracking for it took long enough that the window's end passed before the check finished. Or two threads could check the schedule at once. The next-edge computation is removed: its result was never used (WO-044)
- fix(WO-038): the `onSchedule` event now carries the State after the transition it announces, as Android's does. The SDK took the State before the schedule started or stopped tracking, so a scheduled start arrived with `enabled: false` and a scheduled stop with `enabled: true`. An app following the documented `if (state.enabled)` check handled every start as a stop. The whole State is now current, not just `enabled`: a schedule entry that starts geofences-only tracking reports that `trackingMode`. Swift's `BGGeo.ScheduleEvent.enabled` is corrected with it (WO-038)
- fix(WO-038): when a schedule window's end is noticed after the next window has begun (back-to-back windows, or an end first noticed late, since iOS cannot wake the app at a schedule edge), the next window's start could run before the ending window's stop, leaving tracking stopped for that whole window. Now the ending window stops, then the next one starts, and their `onSchedule` events arrive in that order with `enabled: false` then `enabled: true`, as on Android. A recurring window whose end was missed until it reopened the next day now stops and starts once, where it could previously start twice. An end noticed before the next window begins no longer sends a second, spurious stop event (WO-038)
- fix(WO-041): `ready()` now clears a saved `schedulerEnabled` that has no schedule behind it, as Android always has. Until now iOS relied on a change to the schedule to clear the flag. An app that dropped its `schedule` under an earlier release (whose reset did not notify the SDK) kept reporting the scheduler as enabled. A later release that added a schedule back then resumed it with no `startSchedule()`. The check uses the state saved at launch, so a configuration that brings a schedule back does not revive the flag. It runs inside `ready()` itself, so the `State` that React Native and Cordova resolve `ready()` with is already correct. A scheduler started by `startSchedule()` before `ready()` keeps its flag. `ready()` also no longer re-reads the schedule of a scheduler that is already running. After a `startSchedule()` in that window, the re-read fired the schedule's ON transition twice: a duplicate `onSchedule` event and a second tracking start (WO-041)
- fix(WO-042): `startSchedule()` right after `ready()` could be silently ignored on a relaunch whose schedule was unchanged: React Native and Cordova resolve `ready()` about 0.75 s before the SDK has read the schedule. The scheduler reported "Scheduler #start called with an empty schedule!" and did not start that launch. This regression came with the one-commit reset (WO-039), which no longer re-reads an unchanged schedule on every launch. The scheduler now reads the configured schedule itself when it starts, as on Android. It also covers a `startSchedule()` made before `ready()`, which was ignored the same way before WO-039. Two changes bring the scheduler in line with Android. A schedule the app removed can no longer start again on a later `startSchedule()`: stopping now forgets the old schedule, so starting reads the current configuration. And a `startSchedule()` with nothing to run now turns `schedulerEnabled` off, instead of leaving it reporting a scheduler that is not running (WO-042)
- fix(WO-039): new `-[TSConfig resetWithDictionary:]` (Swift `reset(with:)`) resets the configuration to its defaults and applies a dictionary as ONE change, the counterpart of Android's `TSConfig.reset(JSONObject)`. Every plugin's `ready()` and `reset(config)` used to compose `-reset` or `-resetConfig:YES` with `-updateWithDictionary:`, and both compositions were wrong. `-reset` showed every configuration listener the defaults in between: the empty default `schedule` stopped a persisted scheduler and saved `schedulerEnabled: false`, so the scheduler never resumed on a later launch (Flutter). `-resetConfig:YES` made the update diff against the defaults, so unchanged settings re-notified on every launch — each launch re-parsed the schedule on a second thread — and a setting the new configuration omitted reverted to its default with no notification at all (React Native, Capacitor, Cordova). Listeners now hear only real changes, including a return to the default, and the result is persisted once. `-reset` and `-resetConfig:` are unchanged (WO-039)
- fix(WO-039): the motion detector now takes `activityRecognitionInterval` from the configuration when the tracking service starts. Only that key's change listener ever applied it, and only while moving, so a launch that did not change the value ran the detector at its own 10-second default. Plugins re-notifying unchanged settings on every launch had been hiding this (WO-039)

## 4.7.0 &mdash; 2026-09-23
- test(ios): make the suite independent of main-queue scheduling and of test order

## 4.6.1 &mdash; 2026-09-07
- fix(WO-018): a stationary pause no longer interrupts single-location requests. `TSStationarySentinel` exists to disengage long-lived location *streams*; it was also cancelling every in-flight single-shot request, including the `motionchange` the SDK issues at `stopTimeout` to fix the position where you stopped. Because issuing that request is what turns the radio on, its own first delivered fix was what pushed the sentinel past its window — so the pause reliably destroyed the request that had woken it. Tracking then sat in the stationary state with no stationary-region, discarding every location it received, until the app was relaunched (react-native #2655). Requests now run to their own timeout, and the radio is released when nothing is left to serve. `getCurrentPosition` and geofence trigger-location requests issued during a pause are also no longer failed with a spurious "request was cancelled". Also released as 4.5.2 on the 4.5.x line (WO-018)
- fix(WO-018): the stationary sentinel is no longer armed when no location stream is registered. With no stream there is nothing for a pause to disengage, so its only possible effect was to interrupt whatever single request had turned the radio on (WO-018)
- fix(WO-018): a stationary pause no longer parks `watchPosition` streams — only the polygon hit-tester opts in. A parked stream is un-parked only by the sentinel confirming movement, which requires deliveries on the very manager the pause stopped, so a `watchPosition`-only app went silently dead, with no error, until relaunch. This exemption was specified in the sentinel's original design and was missing from 4.5.0 (WO-018)
- fix(WO-018): a cancelled `motionchange` that has no replacement now clears the SDK's pending-request pointer, and any pending `stopOnStationary` with it. Defence-in-depth: a stale pointer vetoed the retry and every passive recovery path, and a pending stop left armed through a cancellation could later stop tracking on a moving device — persisting `enabled: false`, which a relaunch does not undo (WO-018)

## 4.6.0 &mdash; 2026-09-04
- fix(WO-014)[iOS] `requestPermission('motion')` now reports a denial as `DENIED_ALWAYS` (5) rather than `DENIED` (2). CoreMotion has no request API and never re-prompts once denied, so an iOS motion denial is permanent — only the Settings app can restore it, which is *more* permanent than Android's, where a second ask is possible. Reporting the softer status meant cross-platform apps branching on `DENIED_ALWAYS` to show a settings prompt did so on Android and silently nothing on iOS. `RESTRICTED` (1) is unchanged — system-wide Fitness Tracking being off is a different condition. The location selector and the no-argument form are unaffected (WO-014)
- fix(WO-012): changing `useSignificantChangesOnly`, and switching from location to geofences-only tracking, no longer restart the whole tracking service. Both were implemented as a full internal stop/start, whose teardown emitted a spurious `enabledchange` pair and stopped geofence monitoring — which resets each geofence's entry state, so the following start re-fired `geofenceInitialTriggerEntry` and delivered a phantom ENTER for a geofence the device had never left. Each now re-engages only the location-update mechanism. A real `stop()` still resets entry state, as before (WO-012)
- fix(WO-012): the odometer could jump by the distance to a long-abandoned location — e.g. +7.9 km on a device that had not moved — after any `stop()`/`start()` or tracking-mode round trip, and could book an entire untracked journey (stop at home, drive, start at work) as travelled distance. Resetting the odometer clears its reference point, but the next `motionchange` then substituted a stale reference from elsewhere in the SDK rather than starting fresh. A reset now means what it says: the first fix after it establishes a new reference and accumulates nothing (WO-012)
- fix(WO-012): a successful `motionchange` now advances the SDK's last-known location. It was written only by the location-update stream, so a parked device — updates off, no significant-change deliveries — could hold a last-known position hours old and arbitrarily distant for the life of the process, which fed the relaunch stationary-region placement at terminate (WO-012)
- fix(WO-012): the `motionchange` event now reports the odometer including the leg it just recorded. It was emitted before that leg was added, so breaking out of a stationary region — the largest single step the odometer takes — delivered a `motionchange` carrying the previous total, leaving the app's last-known odometer a full leg behind (WO-012)
- fix(WO-013): setting `useSignificantChangesOnly`, `pausesLocationUpdatesAutomatically`, `showsBackgroundLocationIndicator`, `disableElasticity`, `disableLocationAuthorizationAlert`, `geofenceInitialTriggerEntry` or `enableTimestampMeta` directly on `config.geolocation` from Swift or Objective-C emitted no change event, so the SDK never applied them at runtime — most visibly `showsBackgroundLocationIndicator`, which never reached CoreLocation. Cross-platform plugins (`setConfig()`) were unaffected (WO-013)
- fix(WO-001): import the persisted v4-era TSConfig on the first launch after a 4.x -> 5.x plugin upgrade instead of silently discarding it — enabled/trackingMode/schedulerEnabled, the odometer and the full config (url/headers/params/schedule/authorization/...) are carried over so a device updated OTA resumes tracking; strict no-op when v5 state already exists; the original archive is copied to `TSLocationManager:TSConfig.backup` before the first v5 write, and unarchive failures are now logged. iOS rollback is bytes-preserved, not automatic; on a license-locked App Store build the archive is backed up but not imported, and is not imported retroactively once the license is fixed (WO-001, flutter #1713)
- feat(WO-007): requestPermission accepts an optional selector — nil = everything (location per locationAuthorizationRequest, then motion), "location" = location only, "motion" = Motion & Fitness alone, resolved in the cross-platform AuthorizationStatus domain (CMAuthorizationStatus maps positionally; Authorized ⇒ Always)
- feat(WO-007): the no-argument form now tops up the motion permission after the location flow resolves — the motion prompt moves from start() to requestPermission() for apps that pre-request (dialog count unchanged; promise still resolves with the location status)
- feat(WO-007): SwiftInterface — BGGeo.Permission / BGGeo.PermissionStatus; requestPermission(_:) returns the status as a value and no longer throws on denial (aligned with the Kotlin API)

## 4.5.1 &mdash; 2026-09-01
- fix(WO-009): tracking manager now seeds `activityType` from config at init — the change-listener fires only on value transitions, so the previous hardcoded `AutomotiveNavigation` governed every steady-state launch and road-snapped iOS tracks regardless of the configured value (flutter #1707). Apps that never configure `activityType` now track with the documented default `Other` (no road-snapping) instead of `AutomotiveNavigation`. As a safety net, `startUpdatingLocation` also re-asserts the configured value on every tracking engage.

## 4.5.0 &mdash; 2026-08-30
- feat(WO-006): pause location updates in polygon geofence when the sentinel says the device has stopped
- feat(WO-006): TSStationarySentinel — detect stationarity iOS refuses to report

## 4.4.5 &mdash; 2026-08-27
- fix: getCurrentPosition gate failure must never resolve from cache; source the freshest cached fix

## 4.4.4 &mdash; 2026-08-26
- fix: getCurrentPosition returns cached fix at timeout instead of 408; stop erasing LRS cache

## 4.4.2 &mdash; 2026-08-04
- feat(motion): add activities[] to location + activitychange; log raw CMMotionActivity
- fix(tracking): recover from stationary-with-no-region wedge after failed motionchange fetch

## 4.4.1 &mdash; 2026-07-27
- test(ios): fix TSHttpService_Tests 401 flake (cold main-queue stall); partial
- test(ios): restore process-global state between test classes; 18 failures ->
- fix(ios): watchPosition must stream until stopWatchPosition, not stop at 60s
- fix(ios): stop watchPosition crash when a stream is torn down mid-emission
- Add insertLocation test feature to context menu in settings screen

## 4.4.0 &mdash; 2026-07-24
- feat: implement insertLocation (was an unimplemented stub that hung callers)
- fix: poisoned lastLocation from clock skew

## 4.3.0 &mdash; 2026-07-12
- feat(data): getLocations(query) — paged/queryable location reads (iOS)

## 4.2.1 &mdash; 2026-06-23
- fix(persistence): honor persistMode for all location types; persistMode-aware getCurrentPosition/watchPosition.

Geofence and motionchange locations were force-persisted (and uploaded) regardless of PersistenceConfig.persistMode, because the per-request persist flag was mapped onto the persistMode force-override in TSDataStore. forcePersist
is now derived from location type (Current/Watch only); geofence/motionchange route through shouldPersist: and honor
persistMode. Also fixes the direct force:YES motionchange re-persist in TSTrackingService.

    getCurrentPosition/watchPosition gain explicit-vs-omitted persist semantics via TSConfig.resolvePersistForUserReq
uest:provided: — an explicit persist overrides persistMode + enabled; an omitted value follows the location bucket (e
nabled && persistMode in {All, Location}). Adds a persistProvided tri-state to TSCurrentPositionRequest/TSWatchPositi
onRequest and threads persist: Bool? through SwiftInterface.

    Adds TSPersistMode_Pipeline_Tests integration coverage (persistMode pipeline + resolver + maxRecordsToPersist:0 m
aster switch).

## 4.2.0 &mdash; 2026-06-22
- feat: add onLocationFilter event for filter-rejected locations
- fix: Remove SwiftUI being imported by TSLocationManager.xcframework

## 4.1.10 &mdash; 2026-06-12
- chore(DemoApp2): point tracker host back at production
- feat(DemoApp2): odometerPolicy picker + labeled policy controls in Settings
- test(ios): odometer policy, Kalman seed, geofence-exit coverage
- feat(ios): apply odometerPolicy in TSLocationFilter odometer path
- feat(ios): add geolocation.filter.odometerPolicy config option
- Publish changelog to dist repo as CHANGELOG-iOS.md

## 4.1.6 &mdash; 2026-04-20
- test: drain main queue in flushForTesting to deflake LRS tests

## 4.1.3 &mdash; 2026-04-16
- DemoApp2: fix tracking-mode toggle and add lily-pad geofence test
- remove unused import in TSReachability.m

## 4.1.2 &mdash; 2026-04-10
- feat: recorded_at respects timestampFormat, expose recordedAt on event wrappers
- feat: add PersistenceConfig.timestampFormat option
- Increase wait time when verifying checksum

## 4.1.1 &mdash; 2026-04-08
- make getCurrentPosition gates more stricts in demo app
- Dave's deep dive docs
- feat(licensing): semver-aware validation + polygon-geofencing entitlement enforcement

## 4.1.0 &mdash; 2026-04-06
- feat: replace CocoaLumberjack with custom SQLite-backed logger (TSNativeLogger)

## 4.0.32 &mdash; 2026-04-05
- Clean docs, prepare for Dave's deep dive reports

## 4.0.31 &mdash; 2026-04-02
- Update panel images
- docs: rewrite README with setup, build, test, publish sections
- remove Pods from version control
- Migrate isPowerSaveMode -> new DeviceSettings class
- feat(State): add isFirstBoot property
- chore: pod install (regenerate Pods from Podfile.lock)
- feat(Geofence): add entryState, stateUpdatedAt, hits from TSGeofence
- refactor(Geofence): remove unnecessary dict initializer
- Revert "feat(Geofence): make dict initializer public"
- feat(Geofence): make dict initializer public
- feat(GeofenceEvent): add geofence: BGGeo.Geofence property; add dict init to Geofence
- feat(LocationEvent): add GeofenceTrigger nested struct and mock property
- Add typed State struct, remove getStationaryLocation()
- Rename ConnectivityChangeEvent.hasConnection → isConnected
- Align Swift API naming with Kotlin for cross-platform parity
- Type GeofenceEvent.location as LocationEvent instead of raw dictionary
- Add age and extras properties to LocationEvent
- Add uuid property to LocationEvent
- Add resetOdometer(), type authorization returns with CoreLocation enums
- Move DocsExamplesCompileTest to DemoApp2Tests target
- Add query params to Logger.getLog/emailLog, add uploadLog method
- Update CHANGELOG for 4.0.30
- Remove dead BackgroundGeolocationPlugin class name check
- Add retry to asset checksum verification in publish-ios.sh
- Update CHANGELOG for 4.0.29
- Set framework IPHONEOS_DEPLOYMENT_TARGET to 13.0 to match podspec
- Update CHANGELOG for 4.0.27
- Remove CocoaPods Swift subspec -- SwiftInterface is SPM-only
- Add --local flag to build-ios.sh for local SPM testing
- Don't commit version wtih --bump and --dry-run
- Update CHANGELOG for 4.0.24
- Clean stale entries from Unreleased section
- Add changelog generation to publish script

## 4.0.30 &mdash; 2026-03-26
- Fix Capacitor validation
- Add retry to asset checksum verification in publish-ios.sh

## 4.0.29 &mdash; 2026-03-26
- Set framework IPHONEOS_DEPLOYMENT_TARGET to 13.0 to match podspec

## 4.0.27 &mdash; 2026-03-26
- Remove CocoaPods Swift subspec -- SwiftInterface is SPM-only

## 4.0.25 &mdash; 2026-03-26
- Clean stale entries from Unreleased section
- Add changelog generation to publish script

## 4.0.24 &mdash; 2026-03-25
- Don't show location authorization nag-dialog while !config.enabled

## 4.0.23 &mdash; 2026-03-25
- Hardcode static URLs and license in podspec template
  Remove unnecessary ENV-based templating for homepage, documentation,
  social media URLs, and license fields — these never change between
  releases.
- Fix requestPermission() 30s timeout when user declines Always upgrade
  The upgrade-decline detection in applicationDidBecomeActive was gated
  behind a config.enabled check, so calling requestPermission() before
  ready() (config not enabled) caused the pending request to never resolve.
  Move in-flight authorization request lifecycle (Ask Next Time reset and
  upgrade-decline detection) above the config.enabled/automaticPromptEnabled
  guards so pending requests always complete regardless of tracking state.
- Add transistorAuthorizationToken param to ready()
  BGGeo.ready() now accepts an optional TransistorToken that auto-configures
  http.url and authorization (strategy, tokens, refreshUrl, refreshPayload,
  expires). The token rewrite always applies regardless of reset flag, since
  tokens may refresh between launches.
  DemoApp updated to use the new param, removing manual auth setup from
  the config closure.
  Doc test generator updated to handle bare ready() → ready { _ in }
  conversion for the new required-closure signature.
- Logger.log() accepts LogLevel enum instead of raw String
  The public log() method now takes a LogLevel enum value, preventing
  typos in level strings. Convenience methods (debug, info, warn, error,
  notice) still delegate directly to the ObjC layer via string tags.
  Added LogLevel.tag computed property to map enum cases to the ObjC
  string constants expected by TSLocationManager.log:message:.
- Logger.log() accepts LogLevel enum instead of raw String
  The public log() method now takes a LogLevel enum value, preventing
  typos in level strings. Convenience methods (debug, info, warn, error,
  notice) still delegate directly to the ObjC layer via string tags.
  Added LogLevel.tag computed property to map enum cases to the ObjC
  string constants expected by TSLocationManager.log:message:.
- Add convenience logging methods to Logger (debug, info, warn, error, notice)
  Thin wrappers over log(_:message:) matching the TS and Kotlin SDKs,
  so Swift developers can write bgGeo.logger.debug("msg") instead of
  bgGeo.logger.log("debug", message: "msg").
- Gitignore auto-generated DocsExamplesCompileTest.swift
  This file is regenerated by scripts/generate_docs_compile_test_swift.py
  from docs-db YAML files and should not be tracked.
- Add ready(reset:configure:), type-safe enums, and event improvements
  SwiftInterface API improvements:
  - BGGeo.ready(reset:configure:): config closure is now required (no bare
    ready()). reset=true (default) applies config every launch; reset=false
    applies only on first install, using persisted config on subsequent boots.
  - HttpConfig.method: String → HttpMethod enum (.post, .put, .patch)
  - GeolocationConfig.locationAuthorizationRequest: String →
    LocationAuthorizationRequest enum (.always, .whenInUse, .any)
  - PersistenceConfig.locationsOrderDirection: String →
    LocationsOrderDirection enum (.ascending, .descending)
  - ScheduleEvent: add typed enabled/trackingMode properties
  - AuthorizationEvent: add isSuccess computed property
  - HeartbeatEvent: add typed locationEvent property
  DemoApp updated to use ready(reset: false) { } pattern, replacing
  manual isFirstBoot guard.
  Doc compile test generator updated with Android-only detection and
  expanded to 110 test methods.
- Add pure-Swift Geofence API, removeListeners(), and docs compile verification
  - Geofence struct: add public initializers for circle and polygon geofences
    so developers never need to touch TSGeofence.h directly. GeofenceManager.add()
    and addAll() now accept Geofence instead of TSGeofence.
  - BGGeo.removeListeners(): new method to bulk-remove all event listeners,
    delegates to TSEventManager.removeListeners.
  - generate_docs_compile_test_swift.py: extracts swift: blocks from docs-db
    YAML files and generates DocsExamplesCompileTest.swift for compile verification.
  - DemoApp updated to use pure-Swift Geofence API.
- Add SwiftInterface: pure Swift API for SwiftUI developers
  Introduces a thin Swift proxy layer (BGGeo) wrapping the ObjC TSLocationManager
  singleton with idiomatic Swift patterns: async/await, closure-based event listeners
  with auto-cleanup EventSubscription tokens, typed config sub-modules, and Swift
  structs for all event types.
  - 27 new Swift files in SwiftInterface/ (Config/, Events/, plus module proxies)
  - Token-based event listener lifecycle (TSEventManager returns UUID tokens)
  - ObjC onX methods now return NSString* token (backwards-compatible)
  - Sub-objects: config, logger, store, geofences, authorization, sensors, app
  - TransistorAuthorizationService for demo server auth
  - DemoApp2 fully migrated to new Swift API
  - Removed old SwiftOverlay/TSLocationEvent+Swift.swift
  - Updated CLAUDE.md with SwiftInterface sync instructions
- Rename '## Unreleased' to versioned heading at publish time
  Updates both the private and public CHANGELOG.md, replacing
  '## Unreleased' with '## X.Y.Z &mdash; YYYY-MM-DD' before copying
  to the public repo.
- Add pod install to setup script
- Add setup script and Install section to README
- Add post-commit hook to auto-update CHANGELOG.md
  Appends commit messages under an "## Unreleased" section (created if
  missing). Skips merge commits, strips Co-Authored-By lines, indents
  multi-line bodies. Amends the commit to include the changelog update.
  Set core.hooksPath with: git config core.hooksPath scripts/hooks
- Add JSON POST body support to authorization token refresh.  Port Android SDK behavior: when refreshHeaders contains "Content-Type: application/json", serialize refreshPayload as a JSON body instead of form-encoded. Unrecognized content types fall back to form-encoded for backward compatibility.

## 4.0.22 &mdash; 2026-03-23
- Add watchdog timer for HttpService.  
- ensure http timeoutSeconds is used.
- Fix Capacitor licensing

## 4.0.21 &mdash; 2026-02-26
* Fix bug in geofence event-handling when booted due to geofence event (monitoredGeofences cache is empty).

## 4.0.20 &mdash; 2026-02-24
* Guard against posibility of creating `CLLocationManager` instances on background threads.  Can happen if getCurrentPosition called before ready.
* LocationFilter enabled by default: v5 introduces an on-device geolocation.filter layer (Kalman + kinematic/outlier logic) which can change which samples are delivered to onLocation and how distance deltas are smoothed/adjusted.
* Adaptive default for non-high accuracy: When geolocation.desiredAccuracy is not High/Navigation and the app has not explicitly configured geolocation.filter, the default geolocation.filter.policy now auto-relaxes to PassThrough to avoid overly aggressive rejection on low/medium accuracy profiles.
* Preserve v4 behavior: Set geolocation.filter.policy = PassThrough (and optionally disable Kalman / thresholds) to retain pre-v5 “raw” location behavior.

## 4.0.18 &mdash; 2026-02-21
* messed up build

## 4.0.17 &mdash; 2026-02-21
* loosen TSMotionChangeRequest props (desiredAccuracy 10 -> 20)
* Support sparse config updates on LocationFilter

## 4.0.16 &mdash; 2026-02-16
* Don't enforce JWT format for access-token in TSAuthorization

## 4.0.15 &mdash; 2026-02-15
* Fix bugs in TSLocationRequestService location-satisfier

## 4.0.14 &mdash; 2026-02-07
* Fix bug in Geofence DWELL not firing after refactor of TSLocationRequestService

## 4.0.13 &mdash; 2026-02-04
* Fix single-location request on first launch after install.

## 4.0.12 &mdash; 2026-01-28
* Fix bug in iOS License Validation Failure modal dialog interfering with React Native app launching.  Change to less intrusive alert mechanism.
* Fix bug returning wrong data-structure to watchPosition callback.
* Fix first-launch issue with initial call to `.start()`.
* Fix config.authorization bug (refreshPayload and refreshHeaders being ignored).
* Fix bug in `setOdometer` not resolving its `Promise`

## 4.0.11 &mdash; 2026-01-26
* Fix bug in TSAuthorizationConfig.  was providing custom implementation of updateWithDictionary.  Totally unnecessary since TSConfigModuleBase handles all that under the hood.

## 4.0.9 &mdash; 2026-01-20
* Fixed bug in [TSConfig reset] resetting state params (enabled, isMoving, schedulerEnabled).  It should only reset compound-config modules.
* Implemented isTestFlight detection with "sandboxReceipt"


