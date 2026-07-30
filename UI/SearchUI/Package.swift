// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SearchUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SearchUI",
            targets: ["SearchUI"]
        ),
        .library(
            name: "SearchUIDI",
            targets: ["SearchUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Product"),
        .package(path: "../../Library/Money"),
        .package(path: "../../Component/SearchHistory"),
        .package(path: "../ProductUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../WishlistUI"),
        .package(path: "../ProductActionsUI")
    ],
    targets: [
        .target(
            name: "SearchUI",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "SearchHistory", package: "SearchHistory"),
                .product(name: "ProductUI", package: "ProductUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI", "Navigation"]
        ),
        .target(
            name: "SearchUIDI",
            dependencies: [
                "SearchUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "SearchHistory", package: "SearchHistory"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "WishlistUIDI", package: "WishlistUI"),
                .product(name: "ProductActionsUIDI", package: "ProductActionsUI")
            ],
            path: "Sources/DI"
        )
    ]
)
