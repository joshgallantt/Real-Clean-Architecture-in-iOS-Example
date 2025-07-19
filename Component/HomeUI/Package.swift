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
            name: "HomePresentation",
            targets: ["HomePresentation"]
        ),
        .library(
            name: "HomeUIDI",
            targets: ["HomeUIDI"]
        ),
    ],
    targets: [
        .target(
            name: "HomePresentation",
            dependencies: [],
            path: "Sources/Presentation"
        ),
        .target(
            name: "HomeUIDI",
            dependencies: ["HomePresentation"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "HomeUITests",
            dependencies: ["HomeUIDI"],
            path: "Tests/HomeUITests"
        ),
    ]
)
