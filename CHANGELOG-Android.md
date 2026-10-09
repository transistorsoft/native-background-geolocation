 CHANGELOG

## 4.6.4 &mdash; 2026-10-08
- fix(http): `http.timeout` now sets all four of the HTTP client's limits, and a change to it applies at once. The SDK passed it to OkHttp as the limit on the whole request and on opening the connection, and left OkHttp's read and write limits at their defaults of 10 s. With `http.timeout` above 10000, the default of 60000 included, a request therefore failed with `status: 0` after 10 s without data in either direction: a server that took longer than that to start its response, or an upload that stalled that long on a poor connection, where iOS waits up to `http.timeout`. The records stayed queued and were uploaded again later, so a server that had only been slow to answer could receive them twice. All four limits now follow `http.timeout`. Nothing changes at or below 10000, where the limit on the whole request already ended it first. The client was also built only once, when the SDK starts, so a new `http.timeout`, the one passed to `ready()` included, normally reached it only on the next launch, and a fresh install ran its first launch with 60000. It is now rebuilt whenever the value changes, including by `reset()`; a request already in flight keeps the limits it started with. The same client makes the authorization token refresh, the Transistor demo-server token request and `uploadLog`, which get the same limits (long-standing, RN #2670, WO-092)
- feat(rpc): a server can now make a device delete its queued locations. `"destroyLocations"` is a new command for the response RPC (the `"background_geolocation"` key of an HTTP response body) and does what `destroyLocations()` does. Commands run in the order returned, each starting when the one before it has ended, so `[["stop"], ["destroyLocations"]]` stops tracking and then empties the queue. The pair is ordered, not transactional: a batch that is already being uploaded when the commands arrive is still sent. A version before this one logs `Unknown command: destroyLocations` and runs the commands that follow it (capacitor #406, WO-135)
- fix(rpc): an RPC command no longer stops every RPC command after it. The SDK starts each command of a response when the one before it reports that it has ended, and `startSchedule`, `stopSchedule`, `setOdometer` and `resetOdometer` never reported it: every later command, in that response and in every later one, was queued and not run until the app's process ended. Each now reports it. `setOdometer` and `resetOdometer` report it when their position request ends, so the command after them waits for that. `["setOdometer", 1000]`, a whole number, crashed the app with a `ClassCastException`, and so did an `addGeofence` or `addGeofences` with a whole-number `longitude` or a `loiteringDelay` written as `30000.0`: a number is now read as a number, whichever way JSON wrote it. An exception thrown by a command no longer crashes the app or stops the queue: that command fails, with the exception in the log, and the next one runs (WO-136)

## 4.6.3 &mdash; 2026-10-06
- fix(motion): the motion-activity subscription is now re-registered about once an hour while the device is stationary. The SDK registered it with Play Services when tracking started, at boot and each time it switched to moving, but not on any schedule while it stayed stationary (on Android 12 and older a background relaunch of the app also re-registered it). One that Play Services stopped delivering therefore stayed lost until the next of those, and until then tracking could start only on displacement, once the device was about 150 m away with a usable location: a walk the motion API would have started in its first steps could begin minutes late, or be missed. The stationary watchdog, which already re-registers the stationary geofence about hourly, now re-registers the motion subscription on the same run. That run is periodic background work, which Android defers on a device left still and unplugged (Doze): the runs came about an hour apart at first, then 2 to 12 hours apart, on three test phones. On devices that report the current activity whenever the subscription is registered, the `activitychange` event now fires on each of those runs while stationary, usually with `still`. In a terminated app that report starts the app's process, and with `enableHeadless: true` the headless task then also receives `providerchange` and `connectivitychange`; where `activity.triggerActivities` leaves out the activity reported, the SDK also re-anchors its stationary position there, with a `motionchange` (`isMoving: false`). The subscription is not re-registered in significant-changes mode, which runs without it; in a terminated app with `stopOnTerminate: true`, where a delivery stops the SDK; with `activity.disableMotionActivityUpdates`; or while the activity permission is denied (long-standing, capacitor #407, WO-120)

## 4.6.2 &mdash; 2026-10-05
- fix(logger): a line logged while the SDK's logger finishes starting is no longer lost, and the lines around that moment keep their order. Until its log database is open, the SDK holds its log lines in memory; it then writes them out and switches to the database-backed logger. That happens once per process, on a background thread, while other threads are already logging: a line logged at the moment of the switch was dropped, from logcat and from the log database alike, and a line logged while the held lines were being written out could land ahead of older ones. These are the first lines of a process, including one Android has restarted in the background, so the line lost could be the one that says why the app was started. Every line now reaches the log, in the order it was logged (long-standing, WO-119)
- fix(service): a location the SDK has already processed is no longer handed to it again after Android kills the app's process. `TrackingService` returned `START_REDELIVER_INTENT` for every start, and every location delivered while tracking is such a start. Android keeps a start of that kind until the service stops itself, and with `app.notification.sticky: true` the service never does; without it, it stays up for as long as the device is moving. After a kill, Android delivered every start it had kept to the new process, each up to five times over successive kills, and the SDK processed every one as a live location: the odometer counted the distance again, `onLocation` fired, the location was recorded and uploaded again under a new `uuid` with its original `timestamp`, and stop detection ran against old positions, which the log shows as bursts of `Location-services: OFF` / `ON` and `Re-scaled distanceFilter`. The service now returns `START_STICKY`, so Android drops a start once it has been handled. After a kill, Android still restarts the service, with nothing to deliver, and the service stays up when `notification.sticky` is set or the device is moving (long-standing, RN #2669, WO-114)
- fix(service): a start of one of the SDK's foreground services, which tracking makes for every location, no longer asks ActivityManager on the main thread whether a recovery geofence is armed for it. When Android 14 or later refuses to start a foreground service from the background and the app cannot schedule exact alarms, the SDK arms a geofence around the device for two minutes, whose event is allowed to start the service. Since 4.3.0 every service start looked up that geofence's PendingIntent, a call into the system process on the main thread, although outside those two minutes there is none to find. Where the system process answers slowly with the app in the background, such waits are reported as the app not responding. A service start now looks only when it delivers a launch still waiting to be retried, or within three minutes of a recovery geofence being armed, even by an earlier process of the app (since 4.3.0, WO-115)
- fix(location): `geolocation.filter.trackingAccuracyThreshold: 0` no longer switches off distanceFilter elasticity or freezes the last good location. To the location filter, 0 means no accuracy limit, but two other checks read the same setting as a literal 0 m, which no location satisfies. The speed-based scaling of `distanceFilter` never ran, so a moving device kept the configured `distanceFilter` at every speed and received up to one location per second at speed. The last good location, which stop detection can anchor on, stayed at the first fix after the app started. Both checks now use the default, 100 m, when the threshold is 0 or less. The same applies to `odometerAccuracyThreshold: 0` in the location request `setOdometer()` makes: it now stops at a fix within the 20 m default instead of always taking all three samples. A positive threshold behaves as before. Apps that use 0 now get elasticity, so fewer locations at speed; `geolocation.disableElasticity: true` keeps every location (long-standing, flutter #1718, WO-110)
- fix(service): the fallback stop-detection check retries when it means to. When the check could not conclude (time-based tracking with `distanceFilter: 0` and no location available, for example in a tunnel, or a mock-provider location the stop timer refuses), it was meant to schedule itself again, but it passed its reference location after clearing it, so nothing was scheduled. On a device without the motion-activity permission or whose motion API stays silent, a trip whose locations stopped could then stay in the moving state until the next location arrived. It now retries against the same reference location (long-standing, WO-112)
- fix(service): tracking no longer cancels and re-arms an alarm on the main thread for every location while moving. A watchdog alarm, the fallback stop-detection check for devices without the motion-activity permission or whose motion API stays silent, fires once the locations stop for a minute plus the interval between the last two. Every location pushed that deadline back by cancelling the alarm and scheduling a new one, about a dozen calls into Android system services on the main thread per location; where those answer slowly with the app in the background, the wait was reported as the app not responding. The deadline now moves in memory and the alarm is armed once per period; when it fires before the deadline, it waits out the remainder (long-standing, flutter #1718, WO-111)
- fix(geofence): building a polygon geofence no longer writes three logcat lines. The native code that computes a polygon's enclosing circle logged the circle at verbose level for every polygon, whatever `logger.logLevel` said, and ran two extra passes over the vertices only to print them: with thousands of polygons, a large share of the time `addGeofences()` took (RN #2668). `TSGeofence.Builder` still logs the circle at debug, under the log level (WO-107)
- fix(service): a foreground service's repeat promotion no longer runs on the main thread. Since 4.4.2 every start of a foreground service calls `startForeground()`, and every location delivered while tracking is such a start, so the main thread waited on ActivityManager once per location inside `onStartCommand`. Where ActivityManager answers slowly with the app in the background, Android reported that wait as the app not responding. Repeat promotions now run on a thread each service owns, and starts that arrive while one is queued share it. The service's own stops wait behind its pending promotion: stopping first could bring the service down while its `startForeground()` deadline is still armed, which crashes the app. The polygon-geofencing service's 20-minute stop timeout now uses that same guarded stop instead of an unconditional one (since 4.4.2, flutter #1718, WO-109)
- fix(service): a foreground service no longer rebuilds its notification on the main thread for every location. Since 4.4.2 every start of a foreground service promotes it again with `startForeground()` (the `ForegroundServiceDidNotStartInTimeException` fix), and every location delivered while tracking is such a start. Each re-promotion first rebuilt the notification: a notification-channel lookup, two PackageManager queries for the app's launch activity and a new PendingIntent, four calls into system services on the main thread per location. Where those services answer slowly with the app in the background, the main thread waited long enough for Android to report the app as not responding. The notification is now built once and reused until its configuration or start time changes, and the channel is looked up once per process. Every start still calls `startForeground()` (since 4.4.2, flutter #1718, WO-108)
- fix(geofence): `stop()` no longer blocks the main thread for longer the more geofences are stored. Stopping resets every stored geofence to OUTSIDE, and the SDK did so one geofence at a time, with a read and a write each, inside the listener for Play Services' `removeGeofences`, which Play Services runs on the main thread. With thousands of geofences stored, that held the app's UI for seconds: about 7 s for 7,000, long enough for Android to report the app as not responding. The reset is now one database statement, and every Play Services geofencing listener the SDK registers runs on a thread of the SDK's own, never the main thread. The `geofenceschange` event that `stop()` sends now reports `{on: [], off: []}`, as on iOS: it listed every stored geofence's identifier in `off`, a list the React Native plugin copies on the main thread (long-standing, RN #2667)
- fix(geofence): loading polygon geofences no longer queries Android's PackageManager once per polygon. When the license key lacks the polygon-geofencing add-on, every polygon read from the SDK's database, for `getGeofences()` or a geofence evaluation, made its own `getApplicationInfo()` query to learn whether the app is a debug build, and on older Android versions each query is a call into the system process. With thousands of polygons stored, that was thousands of calls every time. The answer cannot change while the app runs, so the SDK now asks once (since 4.1.1)
- fix(geofence): `activity.triggerActivities` now holds for every departure from the stationary state, as documented and as on iOS. When the motion API reports an activity outside `triggerActivities` (e.g. on_bicycle with `"in_vehicle"`), a stationary-geofence EXIT is denied, and the SDK now re-anchors the stationary region at a fresh fix, as iOS does, emitting a `motionchange` with `isMoving: false`. The EXIT used to be dropped with the region left where it was: the device was already outside it, so it never fired again. Since 4.5.0 the denial rarely held anyway: the EXIT's own location reached the missed-exit location audit, which switched to moving at once whenever the SDK was running in the process, and otherwise the stationary watchdog did within 30 minutes. The audit, the watchdog and the exit-verification probe now apply the same test. STILL never denies a departure, and neither does a device without the activity permission (the EXIT was dropped since 4.0.0; overridden since 4.5.0)
- fix(geofence): a stationary-geofence EXIT is now accepted whenever its triggering location is provably outside the stationary region (`distance - accuracy > radius`), however poor that location's accuracy. An EXIT whose accuracy was 300 m or worse (twice the 150 m region radius) was rejected even when it lay hundreds of metres or kilometres outside, so a real departure waited for the verification probe, the location audit or the stationary watchdog — or, before 4.5.0, was missed entirely. Both such rejections seen in the field were real departures: 953 m out at 300 m accuracy, a departure by underground train found 7 km away 18 minutes later, and 3242 m out at 900 m accuracy, a 5 km round trip that went untracked. The location audit, the verification probe and the stationary watchdog apply the same test, which is the one iOS applies. A coarse EXIT that could still be inside the region is verified with a fresh fix as before (since 4.0.15, capacitor #407)
- fix(config): `http.timeout` of 0 or less now takes the default, 60000 ms, as on iOS. A negative value was stored as `-1`, and the HTTP client is built from the stored value once, when the SDK starts: OkHttp refuses a negative timeout, so the next launch threw an `IllegalStateException` while the SDK initialized. `0` was stored and removed the call and connect timeouts. A value stored by an affected release is corrected the next time the configuration changes. `geolocation.locationTimeout` now has a floor of 1 second, as on iOS, and so does the `timeout` passed to `getCurrentPosition`, which no setting clamps: with play-services-location 21 or later, a timeout of 0 or less made the location request throw (`durationMillis must be greater than 0`) before it started (long-standing, WO-080)

## 4.6.1 &mdash; 2026-09-27
- fix(state): the State now carries `didLaunchInBackground`, always `false` on Android, as the API declares and documents. Android left the key out, so `ready()`, `getState()` and every other State the React Native, Capacitor and Cordova plugins return lacked a field their types declare as a required `boolean`; the Flutter plugin's typed State already read `false`. The key also appears in the configuration dump in the log (WO-031)
- docs(kotlin): `TransistorAuthorizationService` names the demo server with https, `https://tracker.transistorsoft.com`, the `TransistorToken.DEFAULT_URL` that `findOrCreateToken` already uses. The `findOrCreateToken` example passed `http://`, which Android 9+ refuses unless the app allows cleartext traffic (WO-063)
- fix(auth): `destroyTransistorAuthorizationToken(url)` with a url that cannot be parsed, e.g. `"not a url"` or `null`, now resolves instead of never settling: the SDK logged the bad url and returned without calling back, so the plugins' promises and the Kotlin API's `destroyToken` waited forever. It resolves as on iOS, and destroys nothing, since no token can have been cached under such a url. `findOrCreateTransistorAuthorizationToken` with a url whose scheme is not http or https now fails as for any other bad url (so the plugins return their placeholder token) instead of throwing inside the SDK's thread pool without calling back (long-standing, WO-062)
- fix(config): a bare `reset()` now reaches the SDK's logger and HTTP service. `TSConfig.reset()`, which the Kotlin API's `config.reset()` calls, sent the root and per-key change events but not the per-group events (`config:logger`, `config:http`) that every other configuration change sends, and those two listen only there. After the reset the State reported the default `logLevel`, Off, while the SDK kept logging to logcat and to its log database at the level set before, and kept the old `logMaxDays`. The HTTP service kept the old `autoSyncThreshold`, so once a `url` was set again it could wait for that many records before an automatic upload. Both lasted until that setting next changed or the app restarted. A reset now sends the same events as any other change, including the full reset a failed license check performs as the service stops (long-standing, WO-061)
- fix(config): `geolocation.desiredAccuracy`, or the flat `desiredAccuracy`, sent as JSON `null` or as a value that is neither a number nor a string holding a whole number (`"high"`, `"10.0"`, `true`, `{}`, `[]`), now takes the default, High, as `reset()` does. From a plugin it took Low and switched the location filter's policy to PassThrough. The default is defined as an Android `PRIORITY_*` constant, `PRIORITY_HIGH_ACCURACY` = 100, but the cross-platform plugins set `desiredAccuracy` in iOS CoreLocation terms, where 100 is `DesiredAccuracy.Low`. So the SDK requested `PRIORITY_LOW_POWER` instead of `PRIORITY_HIGH_ACCURACY`, and the PassThrough policy switched off the filter's outlier and implied-speed rejection. Both were saved, so they survived a relaunch, and the PassThrough policy stayed even after the app set `desiredAccuracy` again. A `null` reached the SDK from the Capacitor and Cordova plugins, and from the HTTP RPC `setConfig` whichever plugin the app uses; the React Native and Flutter plugins drop a `null` the app passes them, so there the setting keeps its value. The other values reached it from any plugin that passes them on, and from the RPC. The Kotlin and Java API, whose `desiredAccuracy` is an `int` in Android terms, was not affected. An explicit `100` from a plugin still means Low. A Low saved by an affected release is not repaired, because it cannot be told apart from a Low the app chose: an app using `reset: false` keeps it until it sets `desiredAccuracy` and `geolocation.filter.policy` again (since 4.0.0; the PassThrough since 4.0.19, WO-059)
- fix(config): the State reports `app.backgroundPermissionRationale`'s default texts again. It reported `{}` unless the app set them, while the background-permission dialog showed four built-in texts that the State never carried. The State now holds those four: `title` `Allow {applicationName} to access this device's location even when closed or not in use?`, `message` `[CHANGEME] This app collects location data for FEATURE X and FEATURE Y.`, `positiveAction` `Change to "{backgroundPermissionOptionLabel}"` and `negativeAction` `Cancel`. The template tags stay as written; the dialog fills them in when it is shown. A text the app sets replaces only its own default, and what the dialog shows does not change. The defaults are saved with the rest of the configuration, as the notification's `title` and `text` are, so a later change to a default text reaches an existing install only after a reset (since 4.0.0, WO-057)
- fix(config): the stored `app.schedule` no longer grows one layer deeper with every configuration change. On Android 7 to 13 (API 24-33), each commit that changed any setting wrapped the stored schedule in one more read-only wrapper, even when no schedule was configured, and every later commit compared and walked the whole chain. An app that calls `setConfig` very often in one long-lived process, for example to update the notification text on every location, could after thousands of changes overflow the stack inside `setConfig`. The typed Kotlin and Java notification editor did the same to `notification.actions` and `notification.strings`. These collections are now copied when the configuration is built. As a result, a list or map passed to `setSchedule`, `setActions` or `setStrings` is no longer stored as a live view: changing it afterwards no longer changes the configuration without a change event or a save (WO-056)
- fix(WO-050): `activity.triggerActivities` now accepts the array form that the API declares and documents, e.g. `["in_vehicle", "on_foot"]`. Android stored the array's JSON text, `["in_vehicle","on_foot"]`, which matches no activity name, so no detected activity could trigger tracking, and the State echoed the JSON text. The array is now stored as the comma-separated string the SDK has always used, `"in_vehicle,on_foot"`, and the State reports that string, as on iOS. Elements that are not strings are ignored. A value already stored by an affected release is repaired when the configuration is loaded, so an app using `reset: false` recovers on its first launch after the upgrade. The setting is now also stored without whitespace, as on iOS: `"in_vehicle, walking"` reads back as `"in_vehicle,walking"`, and the default as `"in_vehicle,on_bicycle,on_foot,running,walking"` (WO-050)
- fix(config): `setConfig` now merges a partial `geolocation.filter` or `app.notification` block into the current one, as the API documents, as a group's own settings already merge, and as iOS does for `geolocation.filter` (`app.notification` is Android-only). The block used to replace the whole nested group, so every setting it left out went back to its default: `{geolocation: {filter: {policy: 1}}}` after `{geolocation: {filter: {useKalman: false}}}` switched the Kalman filter back on, and `{app: {notification: {title: 'C'}}}` reset the notification's text, icons, channel, layout, actions and strings. The deprecated flat `notification` block, `GeoEditor.setFilter(JSONObject)` and `AppEditor.setNotification(JSONObject)` did the same (long-standing). A setting the block leaves out now keeps its value, and an empty block changes nothing. A setting sent as JSON `null` still goes back to its default; the React Native and Flutter plugins drop a `null` before it reaches the SDK, so there it counts as left out and now keeps its value. `reset(config)` still starts from the defaults (WO-051)
- fix(heartbeat): changing `app.heartbeatInterval` at runtime while tracking is enabled and stationary now re-arms the heartbeat at once. The SDK's listener for that setting declared an `Integer` while the setting is a `double`, so it threw a `ClassCastException` on every change, which the internal event bus swallowed, and nothing was logged. Only a running `TrackingService` re-armed the heartbeat, and while stationary it normally runs only with `notification.sticky: true`, so in significant-changes mode, geofences-only mode or a plain stationary session the change waited for the next stationary transition. Turning the heartbeat on (from the default `-1`) never took effect while the device stayed put, and a new interval took effect only after one more heartbeat at the old one (since 4.0.0)
- fix(proguard): an app that minifies with R8 no longer fails to build with `Missing class com.transistorsoft.locationmanager.data.DataStore`. The Kotlin API classes ship as they were compiled, before R8 runs, so Kotlin callers keep their `@kotlin.Metadata` — which means they call the SDK's internal classes by their source names, and R8 had renamed `DataStore`, the class `BGGeo.getLastLocation(persist = true)` persists its fix through. Apps whose rules carry `-dontwarn com.transistorsoft.**` (the React Native, Flutter and Capacitor plugins) built anyway, and none of those plugins calls the Kotlin API; a native app calling `getLastLocation(persist = true)` reached a class that was not in the AAR. The SDK's own release build now fails if a Kotlin API class refers to any class or method that R8 renamed (since 4.4.2)
- fix(proguard): a Cordova app built with R8 minification now keeps its `BackgroundGeolocationHeadlessTask`. The app supplies that class and nothing references it: the Cordova plugin names it in `headlessJobService` and the SDK loads it with `Class.forName`, so R8 removed it and every headless event was dropped with "HeadlessTask failed to find". The consumer rules now keep it, with its no-arg constructor and `@Subscribe` method(s), whenever the Cordova plugin is present
- fix(config): `NotificationEditor.setString(key, value)` now sets one entry of `app.notification.strings` and keeps the rest. It used to replace the whole map with a one-entry map, so a second call kept only the last entry and a single call erased every string set earlier, e.g. in `ready()`. `setStrings(map)` still replaces the map

## 4.6.0 &mdash; 2026-09-23
- fix(location): a backlog of unprocessed locations no longer costs a thread per LocationResult. `TrackingService` handed every `LocationResult` to the SDK's unbounded cached thread pool, and the task it ran — `TSLocationManager.onLocationResult` — is `synchronized`, so whenever processing ran slower than delivery (verbose logging at a 1 Hz update rate on a low-end device, a batched result after Doze, slow storage) each new LocationResult spawned a worker that immediately parked on the monitor. The live thread count tracked the backlog, and a long session under load churned through thousands of workers, until the kernel refused `pthread_create` and the process died with `OutOfMemoryError: pthread_create (1040KB stack) failed: Try again`, taking the foreground service with it (one field dump: at least 5153 workers created, 278 live, 62 parked at `onLocationResult`). Since 4.3.0 the path-evidence journal write, `synchronized` on its own monitor, was dispatched the same way and added a second such thread per delivery. Each now runs on its own single-thread executor, in delivery order, so a backlog is a queue of small runnables instead of 1 MB thread stacks; the journal keeps its own so a tracking backlog does not delay the evidence geofence transitions read. A backlog of 10 or more logs `Location backlog: N LocationResults unprocessed`, again at each doubling, so a device that cannot keep up with its own update rate says so in the log long before any limit is reached (flutter #1717)
- fix(lifecycle): `setActivity()` called off the main thread no longer touches the Activity's window. `PhoneWindow.getDecorView()` lazily runs the unsynchronized `installDecor()`, so when the Flutter plugin handed over the Activity from a thread pool inside `FlutterActivity.onCreate`, it raced `setContentView()` — leaving the window on an empty DecorView (black screen while the app kept running) or crashing `onCreate` with "Window couldn't find content container view". The window-focus listener is now attached and removed on the main thread, and the Activity lifecycle callbacks no longer depend on the window being reachable (flutter #1715)
- fix(lifecycle): recreating the tracked Activity for a configuration change is no longer treated as app termination — e.g. toggling Bold text, which the default Flutter / React Native `android:configChanges` do not cover, or rotation / dark mode where an app omits them. `onActivityDestroyed` never checked `isChangingConfigurations()`, so the recreation put a foreground app into headless mode (events went only to the headless task, `ready()` was ignored, location-settings dialogs were refused) until the app next came back to the foreground, cleared every client listener, and with `stopOnTerminate: true` stopped tracking. The replacement Activity is now adopted when it starts; a real destroy still terminates as before
- fix(lifecycle): the window-focus listener is now removed when the tracked Activity changes after its window was first drawn. Attached from `onCreate`/`onResume`, the listener lands on the decor's floating `ViewTreeObserver`, which the first traversal merges into the window's observer and then kills — so the removal found a dead observer and left the listener behind. Returning to that window — A → B → A, a Flutter add-to-app engine re-attaching to its Activity, or an Activity relaunched with its window kept for a configuration change — registered a second one, so while tracking was enabled each focus change ran the TerminateEvent one-shot scheduling twice, and a window no longer tracked kept running it
- fix(config): new `TSConfig.reset(JSONObject)` and `TSConfig.editFromDefaults()` reset the configuration and apply the new values as one commit, so config listeners hear only the settings whose value actually changes. Resetting and re-applying as two commits let listeners act on the defaults in between whenever the SDK was configured — a plugin's `reset(config)` while tracking, and, with the lifecycle fix above, `ready()` run again after a recreation: a `WhenInUse` app got the "Allow all the time" background-permission dialog, an app with `disableMotionActivityUpdates: true` got the motion-permission dialog, and `useSignificantChangesOnly: true` switched out of significant-changes mode and back, even with an unchanged configuration. The empty default schedule also switched a running scheduler off in every later launch's `ready()`, which could start tracking outside the schedule window; the scheduler now stays on. The first `ready()` still uploads records queued by an earlier session when `autoSync` is on: that used to be a side effect of the two-commit reset (re-applying `http.url`), and `ready()` now flushes explicitly — with `reset: false` as well. `BGGeo.ready()` uses the one-commit reset. The cross-platform plugins must adopt it too: Capacitor and Flutter do; React Native and Cordova are to follow
- fix(lifecycle): each `TERMINATE_EVENT` one-shot is now evaluated exactly once. `TerminateEvent` registered a permanent headless-change callback per one-shot, so every one-shot stayed registered — whether it logged "ignored" while MainActivity was still alive (window focus lost for 10 s, the Capacitor `handleOnStop` / Cordova `onStop` one-shot) or actually handled a termination — and re-ran at every later termination in the same process. With `stopOnTerminate: false` + `enableHeadless`, a termination preceded by N such one-shots delivered N+1 `terminate` events to the headless task, and each further termination in a process kept alive by a foreground service delivered one more; with `stopOnTerminate: true`, `onActivityDestroy()` ran N extra times. A one-shot now answers on the spot once headless state is known, and on a cold start waits for the first determination as before (regressed in 4.0.18). Separately, `onStart` now clears headless mode before marking lifecycle state known, as `setHeadless()` already did: a read from another thread during a cold launch — a one-shot on the thread pool, or `EventManager`'s headless routing — could see "started" together with the not-yet-cleared default "headless" and treat the launching app as terminated (long-standing)
- fix(lifecycle): with `stopOnTerminate: true`, closing the app while tracking no longer runs the background-launch fail-safe. That check (`Tracking initiated in background with stopOnTerminate: true.  Launch refused.`) is meant for a process's first headless determination only, but its headless-change callback stayed registered and ran again at every real Activity destroy: a normal close logged a false "Launch refused" and ran `onActivityDestroy()` twice. Because the fail-safe disabled tracking first, both of those skipped the significant-changes stop, so in `useSignificantChangesOnly` mode — or where that routing is enforced because the foreground-service permissions are absent — `SlcLocationProvider` and `PassiveLocationProvider` stayed subscribed after termination, and their deliveries were still recorded. The fail-safe is now evaluated exactly once, and when it does refuse a background launch it also stops those providers when they are running in that process (regressed in 4.0.18; the significant-changes gap since 4.1.4, and since 4.3.0 for apps without the foreground-service permissions)
- fix(location): stopping the significant-changes providers now removes their registrations even when the current process never started them. The FLP subscription, the stationary and moving geofences and the stationary-check alarm are OS-level registrations that outlive the process, but `SlcLocationProvider.stop()` / `PassiveLocationProvider.stop()` returned early unless the provider was running in memory — and a process revived by one of those very deliveries has not started it, because the constructor's re-hydration is skipped once `didDeviceReboot` is set. A refused background launch, or a boot that disables tracking, therefore left the previous session subscribed for good: `SlcLocationReceiver` has no enabled gate, so those deliveries kept being recorded while the SDK reported `enabled: false`. Boot's disable branch (where `MY_PACKAGE_REPLACED`, unlike a real reboot, preserves the registrations) and the `stopOnTerminate` terminate path now retire both providers too, matching `stop()` and the scheduler's stop
- fix(geofence): with `stopOnTerminate: true`, going headless no longer re-starts the geofence manager. That restart is meant for a process that keeps tracking headless, but the callback carrying it is retained for the life of the process, so at a real Activity destroy it was dispatched to the thread pool alongside — and racing — the termination teardown that was tearing the same geofences down
- fix(location): starting the foreground-service or geofences-only mechanism now retires the significant-changes one. Every path that STOPS tracking already did this; no path that STARTS it did, and `StartTask` commits the new tracking mode before it computes the routing — so `.startGeofences()` from a live `useSignificantChangesOnly` session could never take the significant-changes branch to clean up after itself. The leftovers were not dormant: `SlcLocationReceiver` has no enabled or tracking-mode gate and persists with force, so geofences-only mode recorded a continuous track and uploaded it. Worse when the switch happened while moving, where the subscription carries no displacement filter: geofence mode forces the stationary state, which is the very state its stationary check requires to downshift, so it sampled at full rate indefinitely — across process deaths, until the app next called `stop()` or `start()`
- fix(boot): a headless relaunch re-hydrates its tracking session again on a device that has rebooted. The re-hydration that restores a session's in-process half — the significant-changes providers, or the foreground-service session's re-arm — was gated on the persisted `didDeviceReboot`, which `BootReceiver` sets on every boot and nothing ever clears, so after a device's first reboot it never ran again. It is meant to skip exactly one process: the one that leaves the start to `BootReceiver`. In significant-changes mode the cost was silent and total: `SlcLocationProvider` registers the only subscriber of the bus its own motionchange is delivered on, so a relaunch without it dropped every motionchange — the stationary-geofence exit included — and the session sat stationary until the user next opened the app. The deferral is now consumed once per detected reboot, like the other post-reboot re-arm signals
- fix(geofence): entering significant-changes mode now retires the geofences-only location sampler. That sampler delivers through a PendingIntent targeting the foreground-service launch gate, so leaving it armed carried a foreground-service launcher into the very mechanism chosen to avoid one
- fix(geofence): the post-reboot geofence rebuild now runs once per reboot instead of on every process start. It fired on the consume-once reboot latch OR the persisted `didDeviceReboot`, and nothing ever clears that flag — so after a device's first reboot every process start forgot the monitored set and re-registered the lot with Play Services, along with the stationary region. The latch (plus the BOOT_COUNT probe that backs it on vendors which never deliver BOOT_COMPLETED) already covers the case on its own

## 4.5.1 &mdash; 2026-09-04
- fix(WO-012): toggling `useSignificantChangesOnly` at runtime no longer restarts the whole tracking session. Both directions of the FGS/significant-change transition routed through a full stop, whose teardown resets each geofence's entry state — so the re-registration that followed delivered a phantom ENTER for a geofence the device was parked inside, and emitted a spurious `enabledchange` pair. Each direction now sheds only what the mechanism change actually requires. A real `stop()` still resets entry state, as before (WO-012)
- feat(permissions): requestPermission(String) accepts "location" / "motion" — request each permission separately with truthful per-permission status (WO-007)
- feat(permissions): PERMISSION_DENIED_ALWAYS status — motion permanently denied, only the app-settings screen can recover (WO-007)
- fix(permissions): serialize all permission requests through an app-global FIFO queue; an OS-cancelled request (empty result array) re-dispatches instead of spuriously reporting granted (WO-007)
- fix(permissions): concurrent permission callers each resolve against their own request — the second caller's permission list is no longer silently discarded (WO-007)
- fix(permissions): duplicate queued requests coalesce onto one OS result — a denied dialog no longer instantly re-appears, which could permanently deny in a single user decision (WO-007)
- hardening(permissions): watchdog + retained host fragment — a result lost to rotation or a finished activity no longer wedges permission requests for the life of the process (WO-007)
- fix(permissions): concurrent flows coalesce onto ONE backgroundPermissionRationale — cancelling no longer reveals a second identical dialog behind the first (WO-008)
- fix(permissions): an externally-dismissed rationale (backgrounded app, phone call) now completes its flow instead of orphaning it — and, unlike click-cancel, does not persist the don't-re-offer suppression (WO-008)
- fix(config): import the persisted v4 (3.x) TSConfig on the first launch after a 4.x -> 5.x plugin upgrade — enabled/trackingMode/schedulerEnabled, the odometer and the full config (url/headers/params/schedule/notification/authorization/...) are carried over so headless fleet devices resume tracking on MY_PACKAGE_REPLACED; strict no-op when v5 state already exists; the legacy TSLocationManager:TSConfig file is retained for rollback, and a rollback followed by a re-upgrade does not re-import (WO-001, flutter #1713)

## 4.5.0 &mdash; 2026-08-15
- fix(config): preserve useCLLocationAccuracy across reset() — stop desiredAccuracy domain oscillation
- feat(geofence): missed-exit sentinel — audit every internal location against the stationary anchor
- fix(geofence): stationary-exit verification, forced re-registration, silent-motion fallback, watchdog

## 4.4.2 &mdash; 2026-08-01
- Demo app notification update odometer
- Update odometer in notification.text
- hardening(service): guarded stop when a promotion throws, never a bare stopSelf()
- feat(motion): add activity.activities[] to location + activitychange payloads
- test(service): assert the GUARDED self-stop, not merely "stopped by self"
- fix(service): promote on EVERY launch — a stale FGS latch was killing restricted apps
- fix(publish): release the staging repo, and gate on Maven Central before tagging

## 4.4.1 &mdash; 2026-07-27
- fix(geofence): recover from a failed deregistration during a geofence re-add
- fix(geofence): allWithinRadius dropped entry_state, hits, state_updated_at
- fix(geofence): revive the coalescing queue; force buffered re-evaluations
- fix(boot): re-arm geofences, tracking and the stationary region after a reboot
- feat(device): recognise Motorola's power-manager screen; first DeviceSettings tests
- feat(demoapp): add Power Manager and Ignore Battery Optimizations menu items
- fix(location): materialize Location extras at ingestion (Android 7 NPE)
- fix(persistence): database failures must degrade, not kill the app
- fix(robustness): guard three recoverable exceptions that killed the app
- hardening(crash): never let last-chance cleanup swallow the crash report
- fix(geofencing): guarantee every delivery releases its startId
- hardening(geofencing): config-driven sticky must respect enabled
- fix(fgs-gate): never queue a warm launch with no drain left to run
- fix(service): keep shared LocationRequestService alive under watch + getCurrentPosition
- fix(service): launch-aware stop to end Motorola FGS DidNotStartInTime crashes
- Add insertLocation test feature in Settings context menu
- feat: implement insertLocation import-as-is; fix uuid column, timestamp, errors

## 4.4.0 &mdash; 2026-07-24
- feat: implement insertLocation import-as-is; fix uuid column, timestamp, errors

## 4.3.3 &mdash; 2026-07-23
- fix(geofence): polygon geofence could fire a phantom ENTER hit-tested against a stale (out-of-order) location sample immediately after a valid EXIT, then cease monitoring on the enclosing-circle exit with the published state stuck "inside". Unconfirmed polygon state-changes are now discarded — never promoted to real events — when monitoring ceases, and polygon hit-testing enforces timestamp monotonicity, rejecting samples older than ones already evaluated.
- fix(geofence): close a polygon MEC-exit race — a transition scored on one thread could complete concurrently with the enclosing-circle EXIT ceasing monitoring on another, stranding the published state "inside". Polygon transition commits and the enclosing-circle cease are now serialized so the terminal state is deterministic; a transition that completes after monitoring has ceased is suppressed.
- fix(geofence): heal polygons left stuck "inside" while unmonitored (the terminal state of the above bugs on already-affected devices), and stop re-firing a spurious polygon ENTER on every app restart. A polygon's enclosing-circle ENTER is no longer suppressed by the duplicate-ENTER guard, so re-entering a site re-engages monitoring; on re-engagement the hit-tester is seeded from the persisted entryState, so a polygon that is still inside stays inside (no phantom re-ENTER) and one the device has actually left fires a correctly-located EXIT. Reconciliation happens through the live hit-tester, never a fabricated event.

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


