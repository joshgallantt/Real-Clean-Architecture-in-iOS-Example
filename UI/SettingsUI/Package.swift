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
                "SettingsUI",
                .product(name: "Settings", package: "Settings")
            ],
            path: "Tests/SettingsUIUnitTests"
        ),
        .testTarget(
            name: "SettingsUIAcceptanceTests",
            dependencies: [
                "SettingsUI",
                .product(name: "Settings", package: "Settings")
            ],
            path: "Tests/SettingsUIAcceptanceTests"
        )
    ]
)
