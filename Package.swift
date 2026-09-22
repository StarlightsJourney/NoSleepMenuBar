// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NoSleep",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "AuthHelper",
            path: "Sources/AuthHelper",
            linkerSettings: [
                .linkedFramework("Security"),
            ]
        ),
        .executableTarget(
            name: "NoSleepHelper",
            path: "Sources/NoSleepHelper"
        ),
        .executableTarget(
            name: "NoSleep",
            dependencies: ["AuthHelper"],
            path: "Sources/NoSleep"
        ),
    ]
)
