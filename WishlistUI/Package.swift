// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WishlistUI",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "WishlistUIDI",
            targets: ["WishlistUIDI"]
        )
    ],
    targets: [
        .target(
            name: "WishlistUI",
            dependencies: [],
            path: "Sources/UI"
        ),
        .target(
            name: "WishlistUIDI",
            dependencies: ["WishlistUI"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "WishlistUITests",
            dependencies: ["WishlistUIDI"],
            path: "Tests/WishlistUITests"
        ),
    ]
)
