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
        .package(path: "../../Component/Session"),
        .package(path: "../ProductUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../../Library/AuthGate")
    ],
    targets: [
        .target(
            name: "WishlistUI",
            dependencies: [
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Product", package: "Product"),
                .product(name: "Session", package: "Session"),
                .product(name: "ProductUI", package: "ProductUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "AuthGate", package: "AuthGate")
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
                .product(name: "Session", package: "Session"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "AuthGate", package: "AuthGate")
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
