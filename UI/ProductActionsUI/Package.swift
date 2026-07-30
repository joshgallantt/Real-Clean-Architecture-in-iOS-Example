// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ProductActionsUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "ProductActionsUI",
            targets: ["ProductActionsUI"]
        ),
        .library(
            name: "ProductActionsUIDI",
            targets: ["ProductActionsUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Wishlist"),
        .package(path: "../../Component/Bag"),
        .package(path: "../../Component/StockAlert"),
        .package(path: "../../Component/Product"),
        .package(path: "../AuthUI"),
        .package(path: "../SnackbarUI")
    ],
    targets: [
        .target(
            name: "ProductActionsUI",
            dependencies: [
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI", "Navigation"]
        ),
        .target(
            name: "ProductActionsUIDI",
            dependencies: [
                "ProductActionsUI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "ProductActionsUIAcceptanceTests",
            dependencies: [
                "ProductActionsUIDI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/ProductActionsUIAcceptanceTests"
        )
    ]
)
