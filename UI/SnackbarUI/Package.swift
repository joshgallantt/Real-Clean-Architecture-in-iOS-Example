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
            name: "SnackbarUIDI",
            dependencies: ["SnackbarUI"],
            path: "Sources",
            exclude: ["SnackbarUI"],
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
