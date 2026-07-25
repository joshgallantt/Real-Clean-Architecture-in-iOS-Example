// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WishlistUI",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "WishlistUI",
            targets: ["WishlistUI"]
        ),
        .library(
            name: "WishlistUIDI",
            targets: ["WishlistUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Wishlist"),
        .package(path: "../../Component/Product"),
        .package(path: "../ProductUI")
    ],
    targets: [
        .target(
            name: "WishlistUI",
            dependencies: [
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Product", package: "Product"),
                .product(name: "ProductUI", package: "ProductUI")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI", "Navigation"]
        ),
        .target(
            name: "WishlistUIDI",
            dependencies: [
                "WishlistUI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "WishlistUITests",
            dependencies: ["WishlistUIDI"],
            path: "Tests/WishlistUITests"
        ),
    ]
)
