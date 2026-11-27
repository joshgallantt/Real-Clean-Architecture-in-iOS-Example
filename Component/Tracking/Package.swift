// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Tracking",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "TrackingTestSupport",
            targets: ["TrackingTestSupport"]
        ),
        .library(
            name: "Tracking",
            targets: ["Tracking"]
        ),
        .library(
            name: "TrackingData",
            targets: ["TrackingData"]
        ),
        .library(
            name: "TrackingDI",
            targets: ["TrackingDI"]
        )
    ],
    dependencies: [
        .package(path: "../Money")
    ],
    targets: [
        .target(
            name: "TrackingTestSupport",
            dependencies: [
                "Tracking",
                "TrackingData",
                .product(name: "Money", package: "Money")
            ],
            path: "Sources/TestSupport"
        ),
        .target(
            name: "Tracking",
            dependencies: [
                .product(name: "Money", package: "Money")
            ],
            path: "Sources",
            exclude: ["DI", "Data", "TestSupport"],
            sources: ["Domain"]
        ),
        .target(
            name: "TrackingData",
            dependencies: [
                "Tracking",
                .product(name: "Money", package: "Money")
            ],
            path: "Sources",
            exclude: ["Domain", "DI", "TestSupport"],
            sources: ["Data"]
        ),
        .target(
            name: "TrackingDI",
            dependencies: [
                "Tracking",
                "TrackingData"
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "TrackingUnitTests",
            dependencies: [
                "Tracking",
                "TrackingData",
                "TrackingTestSupport"
            ],
            path: "Tests/TrackingUnitTests"
        ),
        .testTarget(
            name: "TrackingAcceptanceTests",
            dependencies: [
                "Tracking",
                "TrackingData",
                "TrackingDI",
                "TrackingTestSupport"
            ],
            path: "Tests/TrackingAcceptanceTests"
        )
    ]
)
