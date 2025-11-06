// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "TSLocationManager",
    platforms: [.iOS(.v12)],
    products: [.library(name: "TSLocationManager", targets: ["TSLocationManager"])],
    targets: [
        .binaryTarget(
            name: "TSLocationManager",
            url: "https://github.com/transistorsoft/native-background-geolocation/releases/download/4.0.0-beta.1/TSLocationManager.xcframework.zip",
            checksum: "1f4c43c759d7d25157dadde05d62374d0d1dc9cc73f6c86d54dfaa0a741cba26"
        )
    ]
)
