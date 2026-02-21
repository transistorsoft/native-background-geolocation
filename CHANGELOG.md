# CHANGELOG

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


