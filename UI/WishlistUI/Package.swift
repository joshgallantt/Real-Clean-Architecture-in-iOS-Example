// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WishlistUI",
    platforms: [
        .iOS(.v26)
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
        .package(path: "../../Library/Money"),
        .package(path: "../../Component/Session"),
        .package(path: "../ProductUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../AuthUI"),
        .package(path: "../BagUI"),
        .package(path: "../SharedUI")
    ],
    targets: [
        .target(
            name: "WishlistUI",
            dependencies: [
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "ProductUI", package: "ProductUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "AuthUI", package: "AuthUI")
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
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "BagUIDI", package: "BagUI"),
                .product(name: "SharedUIDI", package: "SharedUI")
            ],
            path: "Sources/DI"
        )
    ]
)
