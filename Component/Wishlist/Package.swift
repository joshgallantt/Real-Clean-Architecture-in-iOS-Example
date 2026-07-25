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
        .package(path: "../Session")
    ],
    targets: [
        .target(
            name: "Wishlist",
            dependencies: [],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "WishlistData",
            dependencies: [
                "Wishlist",
                .product(name: "Session", package: "Session")
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
                .product(name: "Session", package: "Session")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "WishlistTests",
            dependencies: ["WishlistDI"],
            path: "Tests/WishlistTests"
        ),
    ]
)
