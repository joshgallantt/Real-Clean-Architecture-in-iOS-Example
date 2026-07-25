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
        )
    ],
    targets: [
        .target(
            name: "SnackbarUI",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "SnackbarUITests",
            dependencies: ["SnackbarUI"],
            path: "Tests/SnackbarUITests"
        ),
    ]
)
