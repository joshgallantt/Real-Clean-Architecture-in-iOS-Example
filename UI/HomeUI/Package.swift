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
        .package(path: "../../Component/Home"),
        .package(path: "../../Library/Money"),
        .package(path: "../ProductUI"),
        .package(path: "../WishlistUI"),
        .package(path: "../ProductActionsUI")
    ],
    targets: [
        .target(
            name: "HomeUI",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Home", package: "Home"),
                .product(name: "Money", package: "Money"),
                .product(name: "ProductUI", package: "ProductUI")
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
                .product(name: "Home", package: "Home"),
                .product(name: "Money", package: "Money"),
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
                .product(name: "Home", package: "Home"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/HomeUIAcceptanceTests"
        ),
        .testTarget(
            name: "HomeUIUnitTests",
            dependencies: [
                "HomeUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Home", package: "Home"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/HomeUIUnitTests"
        )
    ]
)
