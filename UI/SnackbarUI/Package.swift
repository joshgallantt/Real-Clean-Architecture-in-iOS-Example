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
            name: "SnackbarUITests",
            dependencies: ["SnackbarUI"],
            path: "Tests/SnackbarUITests"
        ),
        .testTarget(
            name: "SnackbarUIHostTests",
            dependencies: ["SnackbarUIDI"],
            path: "Tests/SnackbarUIHostTests"
        )
    ]
)
