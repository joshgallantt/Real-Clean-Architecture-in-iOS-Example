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
        .package(path: "../WishlistUI")
    ],
    targets: [
        .target(
            name: "SearchUI",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Search", package: "Search"),
                .product(name: "ProductUI", package: "ProductUI")
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
                .product(name: "WishlistUIDI", package: "WishlistUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "SearchUITests",
            dependencies: ["SearchUIDI"],
            path: "Tests/SearchUITests"
        ),
    ]
)
