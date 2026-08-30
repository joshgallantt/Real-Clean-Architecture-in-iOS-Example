// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SettingsUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SettingsUI",
            targets: ["SettingsUI"]
        ),
        .library(
            name: "SettingsUIDI",
            targets: ["SettingsUIDI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Settings")
    ],
    targets: [
        .target(
            name: "SettingsUI",
            dependencies: [
                .product(name: "Settings", package: "Settings")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI"]
        ),
        .target(
            name: "SettingsUIDI",
            dependencies: [
                "SettingsUI",
                .product(name: "Settings", package: "Settings")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "SettingsUIUnitTests",
            dependencies: [
                .product(name: "SettingsTestSupport", package: "Settings"),
                "SettingsUI",
                .product(name: "Settings", package: "Settings")
            ],
            path: "Tests/SettingsUIUnitTests"
        ),
        .testTarget(
            name: "SettingsUIAcceptanceTests",
            dependencies: [
                .product(name: "SettingsTestSupport", package: "Settings"),
                "SettingsUI",
                .product(name: "Settings", package: "Settings")
            ],
            path: "Tests/SettingsUIAcceptanceTests"
        ),
        .testTarget(
            name: "SettingsUISnapshotTests",
            dependencies: [
                .product(name: "SettingsTestSupport", package: "Settings"),
                "SettingsUI",
                .product(name: "Settings", package: "Settings"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/SettingsUISnapshotTests"
        )
    ]
)
