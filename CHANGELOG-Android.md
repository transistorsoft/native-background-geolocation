# CHANGELOG

## 4.1.8 &mdash; 2026-06-05
- Release 4.1.7
- Release 4.1.6
- Release 4.1.5
- Release 4.1.4
- refactor(android): drop SLC gap-fill — low hit rate, passive re-center covers the gap
- feat(android): SLC delivery-density bundle — batched + motion-state df + noise filter
- feat(android): Pixel 10 SLC mitigations — stale-reject, gap-fill, passive re-center
- refactor(android): route SLC BR-origin motionchange through SingleLocationJob
- feat(android): SingleLocationJob — WorkManager-backed single-location fetch
- feat(android): TSEventBus.EVENT_SINGLE_LOCATION + SingleLocationResult payload
- feat(android): Conservative LocationFilter on SLC + Passive providers
- feat(android): floor SLC stopTimeout at 20 minutes
- feat(android): SLC moving geofence + CurrentLocationRequest for motionchange
- feat(android): synthesize missed-ENTER transits in GeofenceTriggerGate
- chore(android): GeofencingReceiver finish-grace for onGeofence listener
- feat(android): route geofence PendingIntent through GeofencingReceiver in SLC mode
- feat(android): GeofencingReceiver — non-FGS geofence delivery (not wired)
- feat(android): runtime listener for geolocation.useSignificantChangesOnly
- refactor(android): extract geofence processing into GeofencingProcessor POJO
- chore(demoapp): heartbeat getLastLocation persist=false
- chore(android): tighten SLC location log format + ICON_PIN spacing
- chore(android): log row count in SQLiteLocationDAO.clear
- refactor(android): centralize FLP subscription in SlcLocationProvider
- test(android): unit tests for SlcLocationProcessor
- feat(android): useSignificantChangesOnly routes through non-FGS SlcLocationProvider
- chore(demoapp): passive/SLC test hooks + heartbeat listener
- feat(android): SlcLocationProvider (Phase 1, standalone)
- feat(android): PassiveLocationProvider + getLastLocation() API
- remove Log.d from demoapp
- refactor: extract polygon logic into PolygonGeofencingProcessor
- refactor: relocate GeofenceTriggerGate to .geofence package
- Release 4.1.3
- Release 4.1.2
- Android deep dive doc
- feat: recorded_at respects timestampFormat, expose recordedAt on event wrappers
- feat: add PersistenceConfig.timestampFormat option
- Release 4.1.1
- Release 4.1.1
- Release 4.1.1
- make getCurrentPosition in demoapp more strict
- [feature] add keep.xml rules to circumvent tree-shaking crucial resources
- Add android publishing helper script.  Rename demo app to [BG] Native to differentiate from similarly named public Kotlin demo app
- feat(licensing): semver-aware validation + polygon-geofencing entitlement enforcement
- chore: bump version to 4.1.0
- refactor: replace slf4j/logback-android with native SQLite logger
- Release 4.0.22
- test: add LocationFilter unit tests + disable HTTP posting in test harness
- feat: GPX route loader + real Pixel 6 walking data for tracking test
- feat: MockLocationHelper multi-mode rewrite + working onLocation tracking test
- feat: instrumented test helpers (SDKTestHelper, MockLocationHelper, EventAwaiter)
- test: add LocationAuthorizationTest + document test patterns in CLAUDE.md
- test: add COARSE-only permission tests for SingleLocationRequest
- chore: add TODO with issues found in internal docs
- docs: expand CLAUDE.md with full package map, C++ layer, docs index descriptions
- Get rid of postcommit hook
- Update README
- import Dave's deep dive docs
- Migrate isPowerSaveMode -> DeviceSettings
- feat(Geofence): add entryState, stateUpdatedAt, hits properties
- feat(State): add isFirstBoot property
- docs(kotlin): apply KDoc to NotificationConfig (12 properties) and TransistorToken (4 properties)
- Add State data class, replace enabled/odometer convenience properties
- Remove post-commit changelog hook
- Add KDoc to BGGeo sub-objects, remove stray onLocation in demoapp
- Remove dokka-json-plugin build artifacts, add .gitignore
- Add Dokka JSON exporter plugin and LocationEvent isMock/geofence properties
- Add isMock and geofence properties to LocationEvent
- Add NotificationConfig.kt and complete NotificationConfigEditor
- Add generate_docs_compile_test.py script and gitignore generated test file
- Add DeviceSettings wrapper, enum editor types, rename ConnectivityChangeEvent.isConnected
- Add Kotlin enums for config constants and fix geofenceModeHighAccuracy default
- Apply YAML API docs to Logger.kt methods
- Enhance Kotlin API: Logger query params, uploadLog, event fields
- Apply YAML API documentation as KDoc to Kotlin source files
- Add Dokka HTML documentation generation for Kotlin API
- Add ignore field support to Kotlin doc test generator
- Add transistorAuthorizationToken param to BGGeo.ready()
- Add Logger convenience methods and fix import hoisting in docs test generator
- Add DocsExamplesCompileTest.kt to .gitignore
- Replace JSONObject with Map<String, Any> across Kotlin API surface
- Add required configure closure to BGGeo.ready()
- Add docs-db Kotlin verification script and README skills section
- Add companion object constants to Kotlin API config classes
- Add ProGuard keep rules for Kotlin API classes
- Add Kotlin API interface for tslocationmanager SDK
- Add setup script and Install section to README
- Add post-commit hook for auto-updating CHANGELOG.md and CLAUDE.md
- Add JSON POST support to authorization token refresh
- Implement stationary drift prevention for odometer (iOS parity)
- Update demo app
- Implement new TSGeofence transition EntryState.PENDING_EXIT for dealing with spurious geofence exit events very from the geofence center.  Re-factor TSGeofenceManager to subsribe to TSEventBus for location-updates, rather than relying upon tightly coupled components to call TSGeofenceManager.setLocation
- rename FgsLaunchRx -> FgsLaunchGate in tests
- Rename FgsLaunchRx -> fgsLaunchGate
- Implement new guards for spurious geofence events with new GeofenceTriggerInterrogator module.  will request a new location if anomoly is detected
- null quards
- Add NPE guards on TSLocation and setExtras / getExtras.  Add support for new TSGeofenceTriggerRequest (don't emit samples).  Add new convenience getter for getLastGoodLocation
- Modify log tag
- INtroduce new CurrentLocationRequest subclass TSGeofenceTriggerRequest.  Fix subclassing chain in SingleLocationRequest
- Add new GeofenceTriggerInterrogator module for detecting spurious geofence events
- Add new metrics Type GEOFENCE
- Add convenience method getCenter to TSGeofence to return a Location instance of center coord
- Implement detection of explicitly change TSConfig params.  now when user configures geolocation.desiredAccuracy other than high or navigation, we default filter.policy to PassThrough (unless explicitly set)
- Small tweaks to FgsLaunchRx to disable serviceLaunchDelay on warm boot.  remove unused code
- Update CHANGELOG

## 4.1.7 &mdash; 2026-06-02

## 4.1.6 &mdash; 2026-05-08
- Release 4.1.5
- Release 4.1.4
- refactor(android): drop SLC gap-fill — low hit rate, passive re-center covers the gap
- feat(android): SLC delivery-density bundle — batched + motion-state df + noise filter
- feat(android): Pixel 10 SLC mitigations — stale-reject, gap-fill, passive re-center
- refactor(android): route SLC BR-origin motionchange through SingleLocationJob
- feat(android): SingleLocationJob — WorkManager-backed single-location fetch
- feat(android): TSEventBus.EVENT_SINGLE_LOCATION + SingleLocationResult payload
- feat(android): Conservative LocationFilter on SLC + Passive providers
- feat(android): floor SLC stopTimeout at 20 minutes
- feat(android): SLC moving geofence + CurrentLocationRequest for motionchange
- feat(android): synthesize missed-ENTER transits in GeofenceTriggerGate
- chore(android): GeofencingReceiver finish-grace for onGeofence listener
- feat(android): route geofence PendingIntent through GeofencingReceiver in SLC mode
- feat(android): GeofencingReceiver — non-FGS geofence delivery (not wired)
- feat(android): runtime listener for geolocation.useSignificantChangesOnly
- refactor(android): extract geofence processing into GeofencingProcessor POJO
- chore(demoapp): heartbeat getLastLocation persist=false
- chore(android): tighten SLC location log format + ICON_PIN spacing
- chore(android): log row count in SQLiteLocationDAO.clear
- refactor(android): centralize FLP subscription in SlcLocationProvider
- test(android): unit tests for SlcLocationProcessor
- feat(android): useSignificantChangesOnly routes through non-FGS SlcLocationProvider
- chore(demoapp): passive/SLC test hooks + heartbeat listener
- feat(android): SlcLocationProvider (Phase 1, standalone)
- feat(android): PassiveLocationProvider + getLastLocation() API
- remove Log.d from demoapp
- refactor: extract polygon logic into PolygonGeofencingProcessor
- refactor: relocate GeofenceTriggerGate to .geofence package
- Release 4.1.3
- Release 4.1.2
- Android deep dive doc
- feat: recorded_at respects timestampFormat, expose recordedAt on event wrappers
- feat: add PersistenceConfig.timestampFormat option
- Release 4.1.1
- Release 4.1.1
- Release 4.1.1
- make getCurrentPosition in demoapp more strict
- [feature] add keep.xml rules to circumvent tree-shaking crucial resources
- Add android publishing helper script.  Rename demo app to [BG] Native to differentiate from similarly named public Kotlin demo app
- feat(licensing): semver-aware validation + polygon-geofencing entitlement enforcement
- chore: bump version to 4.1.0
- refactor: replace slf4j/logback-android with native SQLite logger
- Release 4.0.22
- test: add LocationFilter unit tests + disable HTTP posting in test harness
- feat: GPX route loader + real Pixel 6 walking data for tracking test
- feat: MockLocationHelper multi-mode rewrite + working onLocation tracking test
- feat: instrumented test helpers (SDKTestHelper, MockLocationHelper, EventAwaiter)
- test: add LocationAuthorizationTest + document test patterns in CLAUDE.md
- test: add COARSE-only permission tests for SingleLocationRequest
- chore: add TODO with issues found in internal docs
- docs: expand CLAUDE.md with full package map, C++ layer, docs index descriptions
- Get rid of postcommit hook
- Update README
- import Dave's deep dive docs
- Migrate isPowerSaveMode -> DeviceSettings
- feat(Geofence): add entryState, stateUpdatedAt, hits properties
- feat(State): add isFirstBoot property
- docs(kotlin): apply KDoc to NotificationConfig (12 properties) and TransistorToken (4 properties)
- Add State data class, replace enabled/odometer convenience properties
- Remove post-commit changelog hook
- Add KDoc to BGGeo sub-objects, remove stray onLocation in demoapp
- Remove dokka-json-plugin build artifacts, add .gitignore
- Add Dokka JSON exporter plugin and LocationEvent isMock/geofence properties
- Add isMock and geofence properties to LocationEvent
- Add NotificationConfig.kt and complete NotificationConfigEditor
- Add generate_docs_compile_test.py script and gitignore generated test file
- Add DeviceSettings wrapper, enum editor types, rename ConnectivityChangeEvent.isConnected
- Add Kotlin enums for config constants and fix geofenceModeHighAccuracy default
- Apply YAML API docs to Logger.kt methods
- Enhance Kotlin API: Logger query params, uploadLog, event fields
- Apply YAML API documentation as KDoc to Kotlin source files
- Add Dokka HTML documentation generation for Kotlin API
- Add ignore field support to Kotlin doc test generator
- Add transistorAuthorizationToken param to BGGeo.ready()
- Add Logger convenience methods and fix import hoisting in docs test generator
- Add DocsExamplesCompileTest.kt to .gitignore
- Replace JSONObject with Map<String, Any> across Kotlin API surface
- Add required configure closure to BGGeo.ready()
- Add docs-db Kotlin verification script and README skills section
- Add companion object constants to Kotlin API config classes
- Add ProGuard keep rules for Kotlin API classes
- Add Kotlin API interface for tslocationmanager SDK
- Add setup script and Install section to README
- Add post-commit hook for auto-updating CHANGELOG.md and CLAUDE.md
- Add JSON POST support to authorization token refresh
- Implement stationary drift prevention for odometer (iOS parity)
- Update demo app
- Implement new TSGeofence transition EntryState.PENDING_EXIT for dealing with spurious geofence exit events very from the geofence center.  Re-factor TSGeofenceManager to subsribe to TSEventBus for location-updates, rather than relying upon tightly coupled components to call TSGeofenceManager.setLocation
- rename FgsLaunchRx -> FgsLaunchGate in tests
- Rename FgsLaunchRx -> fgsLaunchGate
- Implement new guards for spurious geofence events with new GeofenceTriggerInterrogator module.  will request a new location if anomoly is detected
- null quards
- Add NPE guards on TSLocation and setExtras / getExtras.  Add support for new TSGeofenceTriggerRequest (don't emit samples).  Add new convenience getter for getLastGoodLocation
- Modify log tag
- INtroduce new CurrentLocationRequest subclass TSGeofenceTriggerRequest.  Fix subclassing chain in SingleLocationRequest
- Add new GeofenceTriggerInterrogator module for detecting spurious geofence events
- Add new metrics Type GEOFENCE
- Add convenience method getCenter to TSGeofence to return a Location instance of center coord
- Implement detection of explicitly change TSConfig params.  now when user configures geolocation.desiredAccuracy other than high or navigation, we default filter.policy to PassThrough (unless explicitly set)
- Small tweaks to FgsLaunchRx to disable serviceLaunchDelay on warm boot.  remove unused code
- Update CHANGELOG

## 4.1.5 &mdash; 2026-05-07
- Release 4.1.4
- refactor(android): drop SLC gap-fill — low hit rate, passive re-center covers the gap
- feat(android): SLC delivery-density bundle — batched + motion-state df + noise filter
- feat(android): Pixel 10 SLC mitigations — stale-reject, gap-fill, passive re-center
- refactor(android): route SLC BR-origin motionchange through SingleLocationJob
- feat(android): SingleLocationJob — WorkManager-backed single-location fetch
- feat(android): TSEventBus.EVENT_SINGLE_LOCATION + SingleLocationResult payload
- feat(android): Conservative LocationFilter on SLC + Passive providers
- feat(android): floor SLC stopTimeout at 20 minutes
- feat(android): SLC moving geofence + CurrentLocationRequest for motionchange
- feat(android): synthesize missed-ENTER transits in GeofenceTriggerGate
- chore(android): GeofencingReceiver finish-grace for onGeofence listener
- feat(android): route geofence PendingIntent through GeofencingReceiver in SLC mode
- feat(android): GeofencingReceiver — non-FGS geofence delivery (not wired)
- feat(android): runtime listener for geolocation.useSignificantChangesOnly
- refactor(android): extract geofence processing into GeofencingProcessor POJO
- chore(demoapp): heartbeat getLastLocation persist=false
- chore(android): tighten SLC location log format + ICON_PIN spacing
- chore(android): log row count in SQLiteLocationDAO.clear
- refactor(android): centralize FLP subscription in SlcLocationProvider
- test(android): unit tests for SlcLocationProcessor
- feat(android): useSignificantChangesOnly routes through non-FGS SlcLocationProvider
- chore(demoapp): passive/SLC test hooks + heartbeat listener
- feat(android): SlcLocationProvider (Phase 1, standalone)
- feat(android): PassiveLocationProvider + getLastLocation() API
- remove Log.d from demoapp
- refactor: extract polygon logic into PolygonGeofencingProcessor
- refactor: relocate GeofenceTriggerGate to .geofence package
- Release 4.1.3
- Release 4.1.2
- Android deep dive doc
- feat: recorded_at respects timestampFormat, expose recordedAt on event wrappers
- feat: add PersistenceConfig.timestampFormat option
- Release 4.1.1
- Release 4.1.1
- Release 4.1.1
- make getCurrentPosition in demoapp more strict
- [feature] add keep.xml rules to circumvent tree-shaking crucial resources
- Add android publishing helper script.  Rename demo app to [BG] Native to differentiate from similarly named public Kotlin demo app
- feat(licensing): semver-aware validation + polygon-geofencing entitlement enforcement
- chore: bump version to 4.1.0
- refactor: replace slf4j/logback-android with native SQLite logger
- Release 4.0.22
- test: add LocationFilter unit tests + disable HTTP posting in test harness
- feat: GPX route loader + real Pixel 6 walking data for tracking test
- feat: MockLocationHelper multi-mode rewrite + working onLocation tracking test
- feat: instrumented test helpers (SDKTestHelper, MockLocationHelper, EventAwaiter)
- test: add LocationAuthorizationTest + document test patterns in CLAUDE.md
- test: add COARSE-only permission tests for SingleLocationRequest
- chore: add TODO with issues found in internal docs
- docs: expand CLAUDE.md with full package map, C++ layer, docs index descriptions
- Get rid of postcommit hook
- Update README
- import Dave's deep dive docs
- Migrate isPowerSaveMode -> DeviceSettings
- feat(Geofence): add entryState, stateUpdatedAt, hits properties
- feat(State): add isFirstBoot property
- docs(kotlin): apply KDoc to NotificationConfig (12 properties) and TransistorToken (4 properties)
- Add State data class, replace enabled/odometer convenience properties
- Remove post-commit changelog hook
- Add KDoc to BGGeo sub-objects, remove stray onLocation in demoapp
- Remove dokka-json-plugin build artifacts, add .gitignore
- Add Dokka JSON exporter plugin and LocationEvent isMock/geofence properties
- Add isMock and geofence properties to LocationEvent
- Add NotificationConfig.kt and complete NotificationConfigEditor
- Add generate_docs_compile_test.py script and gitignore generated test file
- Add DeviceSettings wrapper, enum editor types, rename ConnectivityChangeEvent.isConnected
- Add Kotlin enums for config constants and fix geofenceModeHighAccuracy default
- Apply YAML API docs to Logger.kt methods
- Enhance Kotlin API: Logger query params, uploadLog, event fields
- Apply YAML API documentation as KDoc to Kotlin source files
- Add Dokka HTML documentation generation for Kotlin API
- Add ignore field support to Kotlin doc test generator
- Add transistorAuthorizationToken param to BGGeo.ready()
- Add Logger convenience methods and fix import hoisting in docs test generator
- Add DocsExamplesCompileTest.kt to .gitignore
- Replace JSONObject with Map<String, Any> across Kotlin API surface
- Add required configure closure to BGGeo.ready()
- Add docs-db Kotlin verification script and README skills section
- Add companion object constants to Kotlin API config classes
- Add ProGuard keep rules for Kotlin API classes
- Add Kotlin API interface for tslocationmanager SDK
- Add setup script and Install section to README
- Add post-commit hook for auto-updating CHANGELOG.md and CLAUDE.md
- Add JSON POST support to authorization token refresh
- Implement stationary drift prevention for odometer (iOS parity)
- Update demo app
- Implement new TSGeofence transition EntryState.PENDING_EXIT for dealing with spurious geofence exit events very from the geofence center.  Re-factor TSGeofenceManager to subsribe to TSEventBus for location-updates, rather than relying upon tightly coupled components to call TSGeofenceManager.setLocation
- rename FgsLaunchRx -> FgsLaunchGate in tests
- Rename FgsLaunchRx -> fgsLaunchGate
- Implement new guards for spurious geofence events with new GeofenceTriggerInterrogator module.  will request a new location if anomoly is detected
- null quards
- Add NPE guards on TSLocation and setExtras / getExtras.  Add support for new TSGeofenceTriggerRequest (don't emit samples).  Add new convenience getter for getLastGoodLocation
- Modify log tag
- INtroduce new CurrentLocationRequest subclass TSGeofenceTriggerRequest.  Fix subclassing chain in SingleLocationRequest
- Add new GeofenceTriggerInterrogator module for detecting spurious geofence events
- Add new metrics Type GEOFENCE
- Add convenience method getCenter to TSGeofence to return a Location instance of center coord
- Implement detection of explicitly change TSConfig params.  now when user configures geolocation.desiredAccuracy other than high or navigation, we default filter.policy to PassThrough (unless explicitly set)
- Small tweaks to FgsLaunchRx to disable serviceLaunchDelay on warm boot.  remove unused code
- Update CHANGELOG

## 4.1.4 &mdash; 2026-05-06
- refactor(android): drop SLC gap-fill — low hit rate, passive re-center covers the gap
- feat(android): SLC delivery-density bundle — batched + motion-state df + noise filter
- feat(android): Pixel 10 SLC mitigations — stale-reject, gap-fill, passive re-center
- refactor(android): route SLC BR-origin motionchange through SingleLocationJob
- feat(android): SingleLocationJob — WorkManager-backed single-location fetch
- feat(android): TSEventBus.EVENT_SINGLE_LOCATION + SingleLocationResult payload
- feat(android): Conservative LocationFilter on SLC + Passive providers
- feat(android): floor SLC stopTimeout at 20 minutes
- feat(android): SLC moving geofence + CurrentLocationRequest for motionchange
- feat(android): synthesize missed-ENTER transits in GeofenceTriggerGate
- chore(android): GeofencingReceiver finish-grace for onGeofence listener
- feat(android): route geofence PendingIntent through GeofencingReceiver in SLC mode
- feat(android): GeofencingReceiver — non-FGS geofence delivery (not wired)
- feat(android): runtime listener for geolocation.useSignificantChangesOnly
- refactor(android): extract geofence processing into GeofencingProcessor POJO
- chore(demoapp): heartbeat getLastLocation persist=false
- chore(android): tighten SLC location log format + ICON_PIN spacing
- chore(android): log row count in SQLiteLocationDAO.clear
- refactor(android): centralize FLP subscription in SlcLocationProvider
- test(android): unit tests for SlcLocationProcessor
- feat(android): useSignificantChangesOnly routes through non-FGS SlcLocationProvider
- chore(demoapp): passive/SLC test hooks + heartbeat listener
- feat(android): SlcLocationProvider (Phase 1, standalone)
- feat(android): PassiveLocationProvider + getLastLocation() API
- remove Log.d from demoapp
- refactor: extract polygon logic into PolygonGeofencingProcessor
- refactor: relocate GeofenceTriggerGate to .geofence package
- Remove post-commit changelog hook
- Add KDoc to BGGeo sub-objects, remove stray onLocation in demoapp
- Remove dokka-json-plugin build artifacts, add .gitignore
- Add Dokka JSON exporter plugin and LocationEvent isMock/geofence properties
- Add isMock and geofence properties to LocationEvent
- Add NotificationConfig.kt and complete NotificationConfigEditor
- Add generate_docs_compile_test.py script and gitignore generated test file
- Add DeviceSettings wrapper, enum editor types, rename ConnectivityChangeEvent.isConnected
- Add Kotlin enums for config constants and fix geofenceModeHighAccuracy default
- Apply YAML API docs to Logger.kt methods
- Enhance Kotlin API: Logger query params, uploadLog, event fields
- Apply YAML API documentation as KDoc to Kotlin source files
- Add Dokka HTML documentation generation for Kotlin API
- Add ignore field support to Kotlin doc test generator
- Add transistorAuthorizationToken param to BGGeo.ready()
- Add Logger convenience methods and fix import hoisting in docs test generator
- Add DocsExamplesCompileTest.kt to .gitignore
- Replace JSONObject with Map<String, Any> across Kotlin API surface
- Add required configure closure to BGGeo.ready()
- Add docs-db Kotlin verification script and README skills section
- Add companion object constants to Kotlin API config classes
- Add ProGuard keep rules for Kotlin API classes
- Add Kotlin API interface for tslocationmanager SDK
- Add setup script and Install section to README
- Add post-commit hook for auto-updating CHANGELOG.md and CLAUDE.md
- Add JSON POST support to authorization token refresh
- Implement stationary drift prevention for odometer (iOS parity)
- Update demo app
- Implement new TSGeofence transition EntryState.PENDING_EXIT for dealing with spurious geofence exit events very from the geofence center.  Re-factor TSGeofenceManager to subsribe to TSEventBus for location-updates, rather than relying upon tightly coupled components to call TSGeofenceManager.setLocation
- rename FgsLaunchRx -> FgsLaunchGate in tests
- Rename FgsLaunchRx -> fgsLaunchGate
- Implement new guards for spurious geofence events with new GeofenceTriggerInterrogator module.  will request a new location if anomoly is detected
- null quards
- Add NPE guards on TSLocation and setExtras / getExtras.  Add support for new TSGeofenceTriggerRequest (don't emit samples).  Add new convenience getter for getLastGoodLocation
- Modify log tag
- INtroduce new CurrentLocationRequest subclass TSGeofenceTriggerRequest.  Fix subclassing chain in SingleLocationRequest
- Add new GeofenceTriggerInterrogator module for detecting spurious geofence events
- Add new metrics Type GEOFENCE
- Add convenience method getCenter to TSGeofence to return a Location instance of center coord
- Implement detection of explicitly change TSConfig params.  now when user configures geolocation.desiredAccuracy other than high or navigation, we default filter.policy to PassThrough (unless explicitly set)
- Small tweaks to FgsLaunchRx to disable serviceLaunchDelay on warm boot.  remove unused code
- Update CHANGELOG

## 4.1.3 &mdash; 2026-04-10
- Android deep dive doc
- feat: recorded_at respects timestampFormat, expose recordedAt on event wrappers
- feat: add PersistenceConfig.timestampFormat option
- Release 4.1.1
- Release 4.1.1
- Release 4.1.1
- make getCurrentPosition in demoapp more strict
- [feature] add keep.xml rules to circumvent tree-shaking crucial resources
- Add android publishing helper script.  Rename demo app to [BG] Native to differentiate from similarly named public Kotlin demo app
- feat(licensing): semver-aware validation + polygon-geofencing entitlement enforcement
- chore: bump version to 4.1.0
- refactor: replace slf4j/logback-android with native SQLite logger
- Release 4.0.22
- test: add LocationFilter unit tests + disable HTTP posting in test harness
- feat: GPX route loader + real Pixel 6 walking data for tracking test
- feat: MockLocationHelper multi-mode rewrite + working onLocation tracking test
- feat: instrumented test helpers (SDKTestHelper, MockLocationHelper, EventAwaiter)
- test: add LocationAuthorizationTest + document test patterns in CLAUDE.md
- test: add COARSE-only permission tests for SingleLocationRequest
- chore: add TODO with issues found in internal docs
- docs: expand CLAUDE.md with full package map, C++ layer, docs index descriptions
- Get rid of postcommit hook
- Update README
- import Dave's deep dive docs
- Migrate isPowerSaveMode -> DeviceSettings
- feat(Geofence): add entryState, stateUpdatedAt, hits properties
- feat(State): add isFirstBoot property
- docs(kotlin): apply KDoc to NotificationConfig (12 properties) and TransistorToken (4 properties)
- Add State data class, replace enabled/odometer convenience properties
- Remove post-commit changelog hook
- Add KDoc to BGGeo sub-objects, remove stray onLocation in demoapp
- Remove dokka-json-plugin build artifacts, add .gitignore
- Add Dokka JSON exporter plugin and LocationEvent isMock/geofence properties
- Add isMock and geofence properties to LocationEvent
- Add NotificationConfig.kt and complete NotificationConfigEditor
- Add generate_docs_compile_test.py script and gitignore generated test file
- Add DeviceSettings wrapper, enum editor types, rename ConnectivityChangeEvent.isConnected
- Add Kotlin enums for config constants and fix geofenceModeHighAccuracy default
- Apply YAML API docs to Logger.kt methods
- Enhance Kotlin API: Logger query params, uploadLog, event fields
- Apply YAML API documentation as KDoc to Kotlin source files
- Add Dokka HTML documentation generation for Kotlin API
- Add ignore field support to Kotlin doc test generator
- Add transistorAuthorizationToken param to BGGeo.ready()
- Add Logger convenience methods and fix import hoisting in docs test generator
- Add DocsExamplesCompileTest.kt to .gitignore
- Replace JSONObject with Map<String, Any> across Kotlin API surface
- Add required configure closure to BGGeo.ready()
- Add docs-db Kotlin verification script and README skills section
- Add companion object constants to Kotlin API config classes
- Add ProGuard keep rules for Kotlin API classes
- Add Kotlin API interface for tslocationmanager SDK
- Add setup script and Install section to README
- Add post-commit hook for auto-updating CHANGELOG.md and CLAUDE.md
- Add JSON POST support to authorization token refresh
- Implement stationary drift prevention for odometer (iOS parity)
- Update demo app
- Implement new TSGeofence transition EntryState.PENDING_EXIT for dealing with spurious geofence exit events very from the geofence center.  Re-factor TSGeofenceManager to subsribe to TSEventBus for location-updates, rather than relying upon tightly coupled components to call TSGeofenceManager.setLocation
- rename FgsLaunchRx -> FgsLaunchGate in tests
- Rename FgsLaunchRx -> fgsLaunchGate
- Implement new guards for spurious geofence events with new GeofenceTriggerInterrogator module.  will request a new location if anomoly is detected
- null quards
- Add NPE guards on TSLocation and setExtras / getExtras.  Add support for new TSGeofenceTriggerRequest (don't emit samples).  Add new convenience getter for getLastGoodLocation
- Modify log tag
- INtroduce new CurrentLocationRequest subclass TSGeofenceTriggerRequest.  Fix subclassing chain in SingleLocationRequest
- Add new GeofenceTriggerInterrogator module for detecting spurious geofence events
- Add new metrics Type GEOFENCE
- Add convenience method getCenter to TSGeofence to return a Location instance of center coord
- Implement detection of explicitly change TSConfig params.  now when user configures geolocation.desiredAccuracy other than high or navigation, we default filter.policy to PassThrough (unless explicitly set)
- Small tweaks to FgsLaunchRx to disable serviceLaunchDelay on warm boot.  remove unused code
- Update CHANGELOG

## 4.1.2 &mdash; 2026-04-10
- `getCurrentPosition` timeout (408) with approximate (COARSE-only) location permission. With only approximate location granted, the SDK now resolves immediately with the first available location instead of waiting for samples that won't arrive.
- feat: recorded_at respects timestampFormat, expose recordedAt on event wrappers
- feat: add PersistenceConfig.timestampFormat option
- make getCurrentPosition in demoapp more strict

## 4.1.1 &mdash; 2026-04-08
- Release 4.1.1
- make getCurrentPosition in demoapp more strict
- [feature] add keep.xml rules to circumvent tree-shaking crucial resources
- Add android publishing helper script.  Rename demo app to [BG] Native to differentiate from similarly named public Kotlin demo app
- feat(licensing): semver-aware validation + polygon-geofencing entitlement enforcement
- chore: bump version to 4.1.0
- refactor: replace slf4j/logback-android with native SQLite logger
- Release 4.0.22
- test: add LocationFilter unit tests + disable HTTP posting in test harness
- feat: GPX route loader + real Pixel 6 walking data for tracking test
- feat: MockLocationHelper multi-mode rewrite + working onLocation tracking test
- feat: instrumented test helpers (SDKTestHelper, MockLocationHelper, EventAwaiter)
- test: add LocationAuthorizationTest + document test patterns in CLAUDE.md
- test: add COARSE-only permission tests for SingleLocationRequest
- chore: add TODO with issues found in internal docs
- docs: expand CLAUDE.md with full package map, C++ layer, docs index descriptions
- Get rid of postcommit hook
- Update README
- import Dave's deep dive docs
- Migrate isPowerSaveMode -> DeviceSettings
- feat(Geofence): add entryState, stateUpdatedAt, hits properties
- feat(State): add isFirstBoot property
- docs(kotlin): apply KDoc to NotificationConfig (12 properties) and TransistorToken (4 properties)
- Add State data class, replace enabled/odometer convenience properties
- Remove post-commit changelog hook
- Add KDoc to BGGeo sub-objects, remove stray onLocation in demoapp
- Remove dokka-json-plugin build artifacts, add .gitignore
- Add Dokka JSON exporter plugin and LocationEvent isMock/geofence properties
- Add isMock and geofence properties to LocationEvent
- Add NotificationConfig.kt and complete NotificationConfigEditor
- Add generate_docs_compile_test.py script and gitignore generated test file
- Add DeviceSettings wrapper, enum editor types, rename ConnectivityChangeEvent.isConnected
- Add Kotlin enums for config constants and fix geofenceModeHighAccuracy default
- Apply YAML API docs to Logger.kt methods
- Enhance Kotlin API: Logger query params, uploadLog, event fields
- Apply YAML API documentation as KDoc to Kotlin source files
- Add Dokka HTML documentation generation for Kotlin API
- Add ignore field support to Kotlin doc test generator
- Add transistorAuthorizationToken param to BGGeo.ready()
- Add Logger convenience methods and fix import hoisting in docs test generator
- Add DocsExamplesCompileTest.kt to .gitignore
- Replace JSONObject with Map<String, Any> across Kotlin API surface
- Add required configure closure to BGGeo.ready()
- Add docs-db Kotlin verification script and README skills section
- Add companion object constants to Kotlin API config classes
- Add ProGuard keep rules for Kotlin API classes
- Add Kotlin API interface for tslocationmanager SDK
- Add setup script and Install section to README
- Add post-commit hook for auto-updating CHANGELOG.md and CLAUDE.md
- Add JSON POST support to authorization token refresh
- Implement stationary drift prevention for odometer (iOS parity)
- Update demo app
- Implement new TSGeofence transition EntryState.PENDING_EXIT for dealing with spurious geofence exit events very from the geofence center.  Re-factor TSGeofenceManager to subsribe to TSEventBus for location-updates, rather than relying upon tightly coupled components to call TSGeofenceManager.setLocation
- rename FgsLaunchRx -> FgsLaunchGate in tests
- Rename FgsLaunchRx -> fgsLaunchGate
- Implement new guards for spurious geofence events with new GeofenceTriggerInterrogator module.  will request a new location if anomoly is detected
- null quards
- Add NPE guards on TSLocation and setExtras / getExtras.  Add support for new TSGeofenceTriggerRequest (don't emit samples).  Add new convenience getter for getLastGoodLocation
- Modify log tag
- INtroduce new CurrentLocationRequest subclass TSGeofenceTriggerRequest.  Fix subclassing chain in SingleLocationRequest
- Add new GeofenceTriggerInterrogator module for detecting spurious geofence events
- Add new metrics Type GEOFENCE
- Add convenience method getCenter to TSGeofence to return a Location instance of center coord
- Implement detection of explicitly change TSConfig params.  now when user configures geolocation.desiredAccuracy other than high or navigation, we default filter.policy to PassThrough (unless explicitly set)
- Small tweaks to FgsLaunchRx to disable serviceLaunchDelay on warm boot.  remove unused code
- Update CHANGELOG

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


