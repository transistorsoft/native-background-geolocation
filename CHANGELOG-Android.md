# CHANGELOG

## 4.3.2 &mdash; 2026-07-12
- fix(proguard): keep LocationQuery in release minification + consumer rules

## 4.3.1 &mdash; 2026-07-12
- feat(kotlin): DataStore.all(limit/offset/page/order) named params
- feat(data): getLocations(query) — paged/queryable location reads (Android)

## 4.3.0 &mdash; 2026-07-05
- feat: surface rejected geofence triggers on the onLocationFilter event
- feat(geofence): path-evidence ladder for missed-ENTER transits
- feat: best-effort location requests without foreground-service permissions
- feat(fgs): enforce SignificantChanges routing when the FGS permissions are removed from the merged manifest
- chore(service): Phase-4 Stage 0 — delete dead vendor heuristic and the write-only foregroundServiceType plumbing
- feat(fgs)!: non-FGS delivery is now the DEFAULT for geofencing, stationary region, and motion activity
- feat(fgs): drain deferred FGS launches on authorization windows
- chore(service): delete BackgroundTaskService — dead since the 2023 WorkManager refactor
- docs(scheduler): correct exact-alarm log guidance — USE_EXACT_ALARM is Play-restricted
- refactor(geofence): extract static domain API from GeofencingService into TSGeofenceManager
- feat(upgrade): RegistrationMigrator — one-time sweep of stale GMS registrations from earlier SDK versions
- refactor(motion): extract subscription lifecycle from ActivityRecognitionService into motion/MotionActivityManager
- feat(motion): Phase 3 — non-FGS MotionActivityReceiver delivery path (experimental gate)
- refactor(motion): extract MotionActivityProcessor from ActivityRecognitionService
- refactor(motion): drop ActivityRecognitionService's motionTriggerDelay FGS keep-alive
- feat(geofence): delivery-mode stamp — one-time forced re-registration on transition-routing change
- feat(geofence): experimental non-FGS transition-delivery gate + stop-path dual-PI cleanup + 5s confirm timeout
- refactor(geofence): non-FGS delivery for TSGeofenceManager's stationary region (Phase 3, gated)
- refactor(geofence): dedicated StationaryGeofenceReceiver + pluggable exit strategy (Phase 2)
- refactor(geofence): extract SLC stationary-geofence lifecycle into StationaryGeofenceMonitor
- feat(service): StartNotAllowed retry + epoch-scoped gate accounting + force-reopen watchdog
- hardening(service): migrate TrackingService stop to context.stopService (promotion-free)
- hardening(service): route direct FGS-START sites through FgsLaunchGate
- hardening(service): eagerly de-register from sActiveServices on stop()

## 4.2.2 &mdash; 2026-06-30
- fix(android): NullPointerException in TSLocationManagerActivity.onPostCreate on some devices (eg, Samsung / Android 16). The activity hosting the location-services resolution dialog no longer uses AppCompat, avoiding a crash in AppCompat's sub-decor inflation (ContentFrameLayout).

## 4.2.1 &mdash; 2026-06-23
- feat(persistence): persistMode-aware getCurrentPosition/watchPosition (iOS parity)

## 4.2.0 &mdash; 2026-06-22
- feat(demoapp): add Firebase Crashlytics for crash + ANR reporting
- feat: add onLocationFilter event for filter-rejected locations

## 4.1.9 &mdash; 2026-06-12
- chore(demoapp): point tracker host back at production
- feat(demoapp): Location Filter section in Settings sheet
- test(android): odometer Conservative e2e, cold-start, geofence-exit coverage
- feat(android): odometerPolicy in LocationFilter + live filter config listeners
- feat(android): add geolocation.filter.odometerPolicy config option
- Publish changelog to dist repo as CHANGELOG-Android.md

## 4.1.8 &mdash; 2026-06-05
- Fix `setConfig({schedule: [...]})` not re-arming a running scheduler. The scheduler's config-change handler was subscribed to the wrong event bus and never fired; the same dead subscription affected `TSLocationManager` and `TrackingService` config-change handlers. All three now respond to config changes correctly.

## 4.1.7 &mdash; 2026-06-02
- Fix `withPermission()` over-checking background location permission. With foreground location granted but `ACCESS_BACKGROUND_LOCATION` denied, every `watchPosition` / `getCurrentPosition` call fell into the permission-request path unnecessarily — which could crash with `IllegalStateException` when the Activity had already saved its instance state. Foreground permission checks now gate only on the permissions they actually request; background permission remains handled by `withBackgroundPermission()`.

## 4.1.6 &mdash; 2026-05-08
- Fix `desiredAccuracy` regression affecting cross-platform SDKs (React Native / Capacitor / Cordova / Flutter): with `useCLLocationAccuracy: false`, iOS-style `DesiredAccuracy` values (`-1`, `-2`, `10`, …) were passed raw to `FusedLocationProviderClient`, crashing with `"priority -1 must be a PRIORITY_* constant"`. Accuracy values are now translated safely at read time, accepting both Android `PRIORITY_*` constants and CoreLocation-style values.

## 4.1.5 &mdash; 2026-05-07
- Fix `setUseCLLocationAccuracy(true)` becoming a no-op after `reset()`, leaving accuracy translation permanently desynced — CoreLocation-domain values could then reach `LocationRequest.setPriority()` untranslated and crash on `play-services-location` v21+.

## 4.1.4 &mdash; 2026-05-06
- Add SLC-only tracking: with `useSignificantChangesOnly: true`, tracking now runs entirely through the new `SlcLocationProvider` without launching any foreground service — no persistent notification, in exchange for reduced-fidelity, distance-triggered location delivery. Includes SLC-aware stationary detection and responds to `useSignificantChangesOnly` config changes at runtime.
- Add `getLastLocation()` API: a pure last-known-location cache read that returns immediately and never launches a foreground service, with optional persistence into the SDK's database + HTTP pipeline. Backed by a new passive (`PRIORITY_NO_POWER`) provider that keeps the device's location cache warm.
- Geofencing now operates in SLC mode without a foreground service. Missed ENTER transitions are synthesized (plausibility-checked to reject device location resyncs).
- Motion-change fixes are now fetched fresh via `CurrentLocationRequest` (`maxUpdateAgeMillis = 0`) through a WorkManager-backed `SingleLocationJob`, eliminating stale cached fixes that could place a startup `motionchange` kilometres from the device.
- Harden SLC reliability against aggressive delivery throttling (notably Pixel 10 / Android 16): stale-fix rejection on stationary transitions, moving-geofence re-centering from passive fixes, a 20-minute floor on `stopTimeout` in SLC mode (`stopTimeout: 0` opt-out still honored), Conservative `LocationFilter` on SLC / passive streams, and stationary ghost-anchor detection / self-correction.
- Fix HTTP config-change handler reading stale `HttpState`.

## 4.1.3 &mdash; 2026-04-10
- Re-release of 4.1.2 (no code changes).

## 4.1.2 &mdash; 2026-04-10
- Fix `getCurrentPosition` timeout (408) with approximate (COARSE-only) location permission. With only approximate location granted, the SDK now resolves immediately with the first available location instead of waiting for samples that won't arrive.
- Add `PersistenceConfig.timestampFormat` option for customizing the `recorded_at` timestamp format; expose `recordedAt` on event wrappers.

## 4.1.1 &mdash; 2026-04-08
- Fix `getCurrentPosition` treating `desiredAccuracy` / `maximumAge` as bypass flags instead of satisfaction thresholds — `0` or negative values no longer short-circuit sampling with the first available fix.
- Add `keep.xml` resource-keep rules so consumer R8 resource shrinking can no longer strip resources the SDK requires.
- Licensing: semver-aware validation now allows patch releases past subscription expiry on the same `major.minor` line. Polygon geofencing is enforced as a paid entitlement — release builds without the add-on fall back to a circular geofence (debug builds remain fully functional).

## 4.1.0 &mdash; 2026-04-06
- Add KDoc to BGGeo sub-objects, remove stray onLocation in demoapp
- Add generate_docs_compile_test.py script and gitignore generated test file
- Add Dokka JSON exporter plugin
  - Create dokka-json-plugin subproject with DokkaJsonExporterPlugin
  - Generates api.json with kind/name/signature/doc for all Kotlin API elements
  - Run via: ./gradlew :tslocationmanager:dokkaJson
- Add isMock and geofence properties to LocationEvent
  - Add GeofenceTrigger data class (identifier, action, timestamp, extras)
  - Add isMock boolean property
  - Add geofence lazy property for geofence-triggered locations
- Add NotificationConfig.kt and complete NotificationConfigEditor
  - Create read-only NotificationConfig with all 16 properties
  - Expose as AppConfig.notification sub-object
  - Add missing 7 properties to NotificationConfigEditor
- Add DeviceSettings wrapper, enum editor types, rename ConnectivityChangeEvent.isConnected
  - ConfigEditor: kalmanProfile/policy accept enum types directly
  - ConnectivityChangeEvent: rename hasConnection → isConnected
  - Add DeviceSettings + DeviceSettingsRequest Kotlin wrappers
  - Demoapp: use EventSubscription for watchPosition toggle
- Add Kotlin enums for config constants and fix geofenceModeHighAccuracy default
  Replace raw int/string constants with strongly-typed Kotlin enums:
  DesiredAccuracy, HttpMethod, PersistMode, LogLevel, TrackingMode,
  LocationAuthorizationRequest, LocationsOrderDirection, AuthorizationStrategy,
  NotificationPriority, FilterPolicy. Convert LocationFilterPolicy to Java enum.
  Restrict http method to POST/PUT/PATCH. Change geofenceModeHighAccuracy
  default to false. Clean up app/application group naming drift.
- Apply YAML API docs to Logger.kt methods
  Apply KDoc from docs-db YAML for getLog, emailLog, uploadLog,
  destroyLog, debug, info, warn, error, notice. Flattened SQLQuery
  params documented via @param tags from property YAMLs.
- Enhance Kotlin API: Logger query params, uploadLog, event fields
  - Logger: add start/end/order/limit params to getLog() and emailLog(),
    add uploadLog(), ORDER_ASC/DESC constants, convenience log methods,
    make destroyLog() a suspend fun
  - BGGeo: add onNotificationAction() listener
  - LocationEvent: add uuid, age, isSample fields; fix API 26 checks
  - HeartbeatEvent: wrap location as LocationEvent instead of raw TSLocation
  - Tests: add Logger constant and logLevel tests
- Apply YAML API documentation as KDoc to Kotlin source files
  Adds apply_docs_kotlin.py script that reads docs-db/*.yaml files and
  generates KDoc comments for the Kotlin API. Applied 158 docs across
  BGGeo, config classes, events, Logger, Geofence, Sensors, and
  TransistorAuthorizationService.
- Add Dokka HTML documentation generation for Kotlin API
  Configures Dokka 1.9.20 to generate HTML docs scoped to only the
  kotlin/ package, excluding the Java adapter layer.
  Run: ./gradlew :tslocationmanager:dokkaHtml
  Output: tslocationmanager/build/dokka/html/
- Add transistorAuthorizationToken param to BGGeo.ready()
  Virtual token param auto-configures http.url and authorization for the
  Transistor demo server, matching the JS/Swift SDKs. Token rewrite always
  applies (even when reset=false skips the configure closure) since the
  token may refresh between launches.
  Also adds url, apiUrl, refreshUrl to TransistorToken (matching Swift)
  and defaults findOrCreateToken url to tracker.transistorsoft.com.
  Simplifies demoapp to single ready() call with token param.
- Add Logger convenience methods and fix import hoisting in docs test generator
  Add debug(), info(), warn(), error(), notice() shorthand methods to
  Logger.kt, matching the TypeScript and Swift SDK APIs.
  Fix generate_docs_compile_test.py to strip import statements from
  Kotlin code examples before wrapping them in test methods, preventing
  "Expecting an element" compilation errors.
- Add DocsExamplesCompileTest.kt to .gitignore
  Generated ephemeral file should not be committed.
- Replace JSONObject with Map<String, Any> across Kotlin API surface
  Developers should never see JSONObject in the Kotlin SDK. All public
  parameters, return types, and properties now use Map<String, Any> (or
  List<Map<String, Any>> for collections). JSONObject conversion happens
  internally.
  Changed across 10 files:
  - Geofence.Builder.setExtras(), Geofence.extras
  - BGGeo.getCurrentPosition/watchPosition extras params
  - HttpConfig.headers/params, PersistenceConfig.extras
  - ConfigEditor headers/params/extras setters
  - LocationEvent.extras, GeofenceEvent.extras
  - AuthorizationEvent.response, ScheduleEvent.state
  - DataStore.all(), sync(), insert()
  Updated DemoApp to use Map literals instead of JSONObject.
- Add required configure closure to BGGeo.ready()
  Replace bare ready() with ready(reset, configure) matching the iOS Swift
  SDK pattern. The configure closure is required — bare ready() without
  config no longer compiles.
  3-branch behavior:
  - First boot: always apply configure closure
  - Subsequent + reset=true (default): reset config then apply closure
  - Subsequent + reset=false: skip closure, use persisted config
  Update DemoApp to use ready(reset=false) { ... } pattern. Add
  setFirstBoot test hook and 4 tests covering all branches.
- Add docs-db Kotlin verification script and README skills section
  Add scripts/generate_docs_compile_test.py which extracts kotlin: blocks
  from docs-db YAML files and generates a compilable test to verify all
  examples reference valid API methods with correct types.
  Document the translate-docs-kotlin and verify-docs-kotlin Claude Code
  skills in the README.
- Add companion object constants to Kotlin API config classes
  Expose SDK constants through the Kotlin API so users don't need to
  import internal Java classes. Adds constants to:
  - LocationFilterConfig: POLICY_*, KALMAN_PROFILE_*
  - PersistenceConfig: PERSIST_MODE_*
  - Authorization: ACCURACY_AUTHORIZATION_*, PERMISSION_*
  - AppConfig: NOTIFICATION_PRIORITY_*
- Add ProGuard keep rules for Kotlin API classes
  Preserve public class names and members in kotlin/ package
  for both library build and consumer app builds.
- Add Kotlin API interface for tslocationmanager SDK
  Implement complete Kotlin wrapper API (BGGeo, Config, Events, sub-objects)
  mirroring the iOS SwiftInterface. Migrate demoapp from Java BackgroundGeolocation
  API to new Kotlin API. Improve polygon capture HUD layout and extract
  GeofenceSheet as standalone bottom sheet.
- Add setup script and Install section to README
- Add post-commit hook for auto-updating CHANGELOG.md and CLAUDE.md
* Add JSON POST support to authorization token refresh.  Allow refreshAuthorizationToken to POST a JSON body instead of form-encoded when the user configures refreshHeaders with "Content-Type": "application/json". Default behavior (form-encoded).
* Implement stationary drift prevention for odometer (iOS parity)
* Fix bug registering geofences not re-evaluating in geofences-only mode (since no new locations come in).  Create a dummy location with only a timestamp to allow re-evaluation of geofences no matter what.
* Fix reported issue with Activity crash, probably related to timing issue in TSLocationManagerActivity.  Add guards

## 4.0.22 &mdash; 2026-04-03
* Fix something I forget

## 4.0.21 &mdash; 2026-03-13
* Fix bug in `BackgroundTaskManager` not calling .mCallback.onCancel if `onWorkerStopped` is called by the system before the task even starts (preventing the HTTPService from toggling back to "not busy".

## 4.0.20 &mdash; 2026-03-11
- Prevent false app termination when opening transient helper activities (eg: TSLocationManagerActivity) with stopOnTerminate: true.
- LifecycleManager now ignores transient activities when determining headless state, preventing erroneous onHeadlessChange(true) events during normal pause/resume flows.
Also hardened headless-state detection to emit changes only on real transitions.
- Prevent rare TSLocation crash by hardening SingleLocationRequest success paths and guarding null Location inputs.
- [FIXED] Prevent ConcurrentModificationException in LifecycleManager listener dispatch  Resolved a rare crash caused by re-entrant modification of internal listener lists during lifecycle callback dispatch (onHeadlessChange / state-change listeners). Listener invocation now operates on a snapshot of the callback list instead of iterating the live ArrayList, preventing ConcurrentModificationException when listeners are added or removed during callback execution.


## 4.0.19 &mdash; 2026-02-25
* Added TSGeofence.EntryState.PENDING_EXIT to mitigate spurious geofence EXIT events. When an EXIT is received, the geofence transitions to PENDING_EXIT until a follow-up location confirms the device is truly outside; stale pending states automatically normalize back to OUTSIDE after a TTL to prevent “sticky” inside state and missed re-ENTER events.
* Refactored TSGeofenceManager to subscribe to internal TSEventBus location updates (EVENT_LOCATION_UPDATE) instead of requiring other SDK components to call TSGeofenceManager.setLocation(...) directly, reducing coupling and centralizing geofence evaluation input
TSGeofenceManager threading by introducing a dedicated HandlerThread to serialize internal location-update handling and state transitions off the main thread, reducing contention and preventing concurrent setLocation/evaluation bursts..
* LocationFilter enabled by default: v5 introduces an on-device geolocation.filter layer (Kalman + kinematic/outlier logic) which can change which samples are delivered to onLocation and how distance deltas are smoothed/adjusted.
* Adaptive default for non-high accuracy: When geolocation.desiredAccuracy is not High/Navigation and the app has not explicitly configured geolocation.filter, the default geolocation.filter.policy now auto-relaxes to PassThrough to avoid overly aggressive rejection on low/medium accuracy profiles.
* Preserve v4 behavior: Set geolocation.filter.policy = PassThrough (and optionally disable Kalman / thresholds) to retain pre-v5 “raw” location behavior.

## 4.0.18
* Android: Migrated FGS launch readiness gating (FgsLaunchReceiver “ready” / EVENT_READY flow) from the legacy HeadlessBroadcastTx path to the centralized EventManager pipeline. This unifies FGS launch + headless event sequencing behind EventManager and improves correctness/consistency of readiness gating across foreground-service starts.
* Android support sparse config updates on app.notification, LocationFilter

## 4.0.17
* Fix bug stopping already-stopped `BackgroundTaskWorker` (log warning churn)

## 4.0.16
* Fix issues in TSGeofenceManager life-cycle during reboot to FG when process already alive in BG.
* Refactor GeofenceDAO queries
* Android: Improved reliability of background foreground-service launches by routing PendingIntent triggers through FgsLaunchReceiver (broadcast proxy + optional first-launch delay) to reduce ForegroundServiceDidNotStartInTimeException crashes. Added coordinated headless-event gating (HEADLESS_PAUSE/RESUME) so headless events drain only after services reach startForeground().
* Refactor new ServiceLaunchReceiver to decouple from AbstractService and HeadlessEventBroadcaster via TSEventBus events intead.
* Fix issue with device-reboot detection.
* Rename ServiceLaunchReceiver -> FgsLaunchReceiver

## 4.0.15
* Fix TSAuthorization regression enforcing JWT format in accessToken.  will hunt for data purely based upon the key-name.

## 4.0.14
* Hot fix error in consumer-rules.pro

## 4.0.13
* Fix issues with location-satisfier in SingleLocationRequest
* Implement new ServiceLaunchReceiver to handle all foreground-service launches in one place, with cold-boot detection and delaying FGS launches in a queue.
* Implement queue for HeadlessEventBroadcaster to queue events until ServiceLaunchReceiver has emptied is FGS launch-queue.


