// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Settings",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SettingsTestSupport",
            targets: ["SettingsTestSupport"]
        ),
        .library(
            name: "Settings",
            targets: ["Settings"]
        ),
        .library(
            name: "SettingsData",
            targets: ["SettingsData"]
        ),
        .library(
            name: "SettingsDI",
            targets: ["SettingsDI"]
        )
    ],
    dependencies: [
        .package(path: "../Session")
    ],
    targets: [
        .target(
            name: "SettingsTestSupport",
            dependencies: [
                "Settings"
            ],
            path: "Sources/TestSupport"
        ),
        .target(
            name: "Settings",
            dependencies: [
                .product(name: "Session", package: "Session")
            ],
            path: "Sources",
            exclude: ["DI", "Data", "TestSupport"],
            sources: ["Domain"]
        ),
        .target(
            name: "SettingsData",
            dependencies: [
                "Settings",
                .product(name: "Session", package: "Session")
            ],
            path: "Sources",
            exclude: ["Domain", "DI", "TestSupport"],
            sources: ["Data"]
        ),
        .target(
            name: "SettingsDI",
            dependencies: [
                "Settings",
                "SettingsData",
                .product(name: "Session", package: "Session")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "SettingsUnitTests",
            dependencies: [
                .product(name: "SessionTestSupport", package: "Session"),
                "Settings",
                .product(name: "Session", package: "Session")
            ],
            path: "Tests/SettingsUnitTests"
        ),
        .testTarget(
            name: "SettingsAcceptanceTests",
            dependencies: [
                .product(name: "SessionTestSupport", package: "Session"),
                "Settings",
                "SettingsDI",
                "SettingsData",
                .product(name: "Session", package: "Session")
            ],
            path: "Tests/SettingsAcceptanceTests"
        )
    ]
)
