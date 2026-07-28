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
        .package(path: "../../Component/Search"),
        .package(path: "../ProductUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../WishlistUI"),
        .package(path: "../BagUI")
    ],
    targets: [
        .target(
            name: "SearchUI",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Search", package: "Search"),
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
                .product(name: "Search", package: "Search"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "WishlistUIDI", package: "WishlistUI"),
                .product(name: "BagUIDI", package: "BagUI")
            ],
            path: "Sources/DI"
        )
    ]
)
