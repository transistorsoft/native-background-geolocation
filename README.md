<p align="center">
  <img src="assets/images/panel-all.svg" alt="Background Geolocation SDK" width="700">
</p>

# Background Geolocation SDK — iOS & Android

The most sophisticated background **location-tracking & geofencing** SDK with battery-conscious motion-detection intelligence for **iOS** and **Android**.

---

## :books: Documentation

### <img src="assets/images/platforms/kotlin.svg" width="20" height="20"> Kotlin
- [Setup](https://docs.transistorsoft.com/kotlin/setup/)
- [API Reference](https://docs.transistorsoft.com/kotlin/BGGeo/)

### <img src="assets/images/platforms/swift.svg" width="20" height="20"> Swift
- [Setup](https://docs.transistorsoft.com/swift/setup/)
- [API Reference](https://docs.transistorsoft.com/swift/BGGeo/)

---

## How it works

The SDK uses **motion-detection** APIs (accelerometer, gyroscope, magnetometer) to detect when the device is *moving* or *stationary*:

- **Moving** — location recording starts automatically at the configured `distanceFilter` (metres)
- **Stationary** — location services turn off automatically to conserve battery

---

## SDK availability

| Platform | Package |
|---|---|
| <img src="assets/images/platforms/swift.svg" width="16" height="16"> Swift / iOS | **This repo** |
| <img src="assets/images/platforms/kotlin.svg" width="16" height="16"> Kotlin / Android | **This repo** |
| <img src="assets/images/platforms/react-native.svg" width="16" height="16"> [React Native](https://github.com/transistorsoft/react-native-background-geolocation) | `react-native-background-geolocation` |
| <img src="assets/images/platforms/expo.svg" width="16" height="16"> [Expo](https://github.com/transistorsoft/react-native-background-geolocation) | `react-native-background-geolocation` |
| <img src="assets/images/platforms/flutter.svg" width="16" height="16"> [Flutter](https://github.com/transistorsoft/flutter_background_geolocation) | `flutter_background_geolocation` |
| <img src="assets/images/platforms/capacitor.svg" width="16" height="16"> [Capacitor](https://github.com/transistorsoft/capacitor-background-geolocation) | `@transistorsoft/capacitor-background-geolocation` |
| <img src="assets/images/platforms/cordova.svg" width="16" height="16"> [Cordova](https://github.com/transistorsoft/cordova-background-geolocation-lt) | `cordova-background-geolocation-lt` |

---

## License

The Android SDK requires a license for **release** builds.
[Purchase a license](https://shop.transistorsoft.com/products/background-geolocation-for-native-apps) — debug builds work without one.

---

MIT © [Transistor Software](https://www.transistorsoft.com)
