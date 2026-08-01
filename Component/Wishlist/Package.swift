// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Wishlist",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Wishlist",
            targets: ["Wishlist"]
        ),
        .library(
            name: "WishlistData",
            targets: ["WishlistData"]
        ),
        .library(
            name: "WishlistDI",
            targets: ["WishlistDI"]
        )
    ],
    dependencies: [
        .package(path: "../Session"),
        .package(path: "../Product")
    ],
    targets: [
        .target(
            name: "Wishlist",
            dependencies: [
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "WishlistData",
            dependencies: [
                "Wishlist",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["Domain", "DI"],
            sources: ["Data"]
        ),
        .target(
            name: "WishlistDI",
            dependencies: [
                "Wishlist",
                "WishlistData",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "WishlistUnitTests",
            dependencies: [
                "Wishlist",
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/WishlistUnitTests"
        ),
        .testTarget(
            name: "WishlistAcceptanceTests",
            dependencies: [
                "WishlistDI",
                "WishlistData",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/WishlistAcceptanceTests"
        )
    ]
)
