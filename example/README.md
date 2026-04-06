# BGGeoDemo — Example Apps

Example apps demonstrating the Native Background Geolocation SDK for iOS (Swift) and Android (Kotlin).

| Platform | Location | Language |
|---|---|---|
| iOS | `ios/` | Swift / SwiftUI |
| Android | `android/` | Kotlin |

---

## iOS

### Requirements

- Xcode 15+
- iOS 16+ device or simulator
- A valid `TSLocationManagerLicense` key (the one in `Info.plist` is bound to `com.transistorsoft.tslocationmanager.demo` — replace it with your own for a different bundle ID)

### Setup

1. Open `ios/` as a **Swift Package** in Xcode — `File → Open` and select the `ios/` folder, or open via `Package.swift` if present. Alternatively open the parent workspace if one exists.
2. **Rename the app to BGGeoDemo:** In Xcode, select the target → **General → Display Name**, set it to `BGGeoDemo`. Also rename the target and scheme via **Editor → Rename** to keep things consistent.
3. Set your **Team** in **Signing & Capabilities**.
4. Select a device or simulator and run.

### Background Modes

The following are already configured in `Info.plist`:

- Location updates
- Background fetch
- Background processing
- Audio (keeps the app alive during suspension)

---

## Android

### Requirements

- Android Studio Hedgehog or later
- Android SDK 29+
- A valid license key (the `TSLocationManagerLicense` metadata in `AndroidManifest.xml` is bound to `com.transistorsoft.tslocationmanager.demo`)

### Setup

1. Open the `android/` folder in Android Studio as an existing project.
2. The app name is already set to **BGGeoDemo** in `res/values/strings.xml`.
3. To use your own `applicationId`, update `build.gradle.kts`:
   ```kotlin
   applicationId = "com.your.package.name"
   ```
   and replace the license key in `AndroidManifest.xml` with one generated for that identifier.
4. Run on a device or emulator.

### Gradle ext vars

Pin SDK versions in the root `build.gradle` / `build.gradle.kts`:

```kotlin
ext["playServicesLocationVersion"] = "21.3.0"
ext["tslocationmanagerVersion"]    = "4.0.+"
```

---

## Demo Server

Both apps are pre-configured to post locations to the [Transistor Software Demo Server](https://tracker.transistorsoft.com), a free hosted endpoint for development and testing.

> [!NOTE]
> The demo server is for development purposes only. Do not use it in production.
