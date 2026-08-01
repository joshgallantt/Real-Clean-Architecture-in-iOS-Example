// swift-tools-version: 6.2

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
        .package(path: "../ProductUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../WishlistUI"),
        .package(path: "../ProductActionsUI")
    ],
    targets: [
        .target(
            name: "HomeUI",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "ProductUI", package: "ProductUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
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
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "WishlistUIDI", package: "WishlistUI"),
                .product(name: "ProductActionsUIDI", package: "ProductActionsUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "HomeUIAcceptanceTests",
            dependencies: [
                "HomeUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/HomeUIAcceptanceTests"
        ),
        .testTarget(
            name: "HomeUIUnitTests",
            dependencies: [
                "HomeUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/HomeUIUnitTests"
        )
    ]
)
