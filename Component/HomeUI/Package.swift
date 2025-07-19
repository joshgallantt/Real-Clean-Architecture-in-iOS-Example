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
            name: "HomeDI",
            targets: ["HomeDI"]
        ),
    ],
    targets: [
        .target(
            name: "HomePresentation",
            dependencies: [],
            path: "Sources/Presentation"
        ),
        .target(
            name: "HomeDI",
            dependencies: ["HomePresentation"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "HomeUITests",
            dependencies: ["HomeDI"],
            path: "Tests/HomeUITests"
        ),
    ]
)
