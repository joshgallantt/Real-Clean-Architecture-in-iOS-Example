// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SnackbarUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SnackbarUI",
            targets: ["SnackbarUI"]
        ),
        .library(
            name: "SnackbarUITestSupport",
            targets: ["SnackbarUITestSupport"]
        ),
        .library(
            name: "SnackbarUIDI",
            targets: ["SnackbarUIDI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0")
    ],
    targets: [
        .target(
            name: "SnackbarUI",
            dependencies: [],
            path: "Sources/SnackbarUI"
        ),
        .target(
            name: "SnackbarUITestSupport",
            dependencies: ["SnackbarUI"],
            path: "Sources/TestSupport"
        ),
        .target(
            name: "SnackbarUIDI",
            dependencies: ["SnackbarUI"],
            path: "Sources",
            exclude: ["SnackbarUI", "TestSupport"],
            sources: ["SnackbarUIHost", "SnackbarUIDI"]
        ),
        .testTarget(
            name: "SnackbarUISnapshotTests",
            dependencies: [
                "SnackbarUI",
                "SnackbarUIDI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/SnackbarUISnapshotTests"
        )
    ]
)
