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
            name: "CartUIDI",
            targets: ["CartUIDI"]
        )
    ],
    targets: [
        .target(
            name: "CartUI",
            dependencies: [],
            path: "Sources/UI"
        ),
        .target(
            name: "CartUIDI",
            dependencies: ["CartUI"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "CartUITests",
            dependencies: ["CartUIDI"],
            path: "Tests/CartUITests"
        ),
    ]
)
