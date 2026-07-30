// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HomeUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "HomeUI",
            targets: ["HomeUI"]
        ),
        .library(
            name: "HomeUIDI",
            targets: ["HomeUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Product"),
        .package(path: "../../Library/Money"),
        .package(path: "../SnackbarUI"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "HomeUI",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI", "Navigation"]
        ),
        .target(
            name: "HomeUIDI",
            dependencies: [
                "HomeUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources/DI"
        )
    ]
)
