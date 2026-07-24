// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BagUI",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "BagUI",
            targets: ["BagUI"]
        ),
        .library(
            name: "BagUIDI",
            targets: ["BagUIDI"]
        )
    ],
    targets: [
        .target(
            name: "BagUI",
            dependencies: [],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI", "Navigation"]
        ),
        .target(
            name: "BagUIDI",
            dependencies: ["BagUI"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "BagUITests",
            dependencies: ["BagUIDI"],
            path: "Tests/BagUITests"
        ),
    ]
)
