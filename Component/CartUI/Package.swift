// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CartUI",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "CartPresentation",
            targets: ["CartPresentation"]
        ),
        .library(
            name: "CartUIDI",
            targets: ["CartUIDI"]
        ),
    ],
    targets: [
        .target(
            name: "CartPresentation",
            dependencies: [],
            path: "Sources/Presentation"
        ),
        .target(
            name: "CartUIDI",
            dependencies: ["CartPresentation"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "CartUITests",
            dependencies: ["CartUIDI"],
            path: "Tests/CartUITests"
        ),
    ]
)
