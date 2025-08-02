// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HomeUI",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "HomeUIDI",
            targets: ["HomeUIDI"]
        )
    ],
    targets: [
        .target(
            name: "HomeUI",
            dependencies: [],
            path: "Sources/UI"
        ),
        .target(
            name: "HomeUIDI",
            dependencies: ["HomeUI"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "HomeUITests",
            dependencies: ["HomeUIDI"],
            path: "Tests/HomeUITests"
        ),
    ]
)
