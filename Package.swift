// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacStatsOverlay",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MacStatsOverlay",
            path: "Sources/MacStatsOverlay",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
            ]
        )
    ]
)
