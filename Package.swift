// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "TSLocationManager",
    platforms: [.iOS(.v12)],
    products: [.library(name: "TSLocationManager", targets: ["TSLocationManager"])],
    dependencies: [
        .package(url: "https://github.com/transistorsoft/transistor-background-fetch", from: "4.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "TSLocationManager",
            dependencies: ["TSBackgroundFetch"],
            url: "https://github.com/transistorsoft/native-background-geolocation/releases/download/4.0.0-beta.1/TSLocationManager.xcframework.zip",
            checksum: "85957849bc9bf50b4f719c620a36bf3e6f50fb9ff0180d13031321f47ee26e46"
        )
    ]
)
