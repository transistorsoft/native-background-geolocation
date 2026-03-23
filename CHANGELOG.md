# CHANGELOG

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

## 4.0.17 &mdash; 2016-02-21
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


