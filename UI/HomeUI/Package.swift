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
            name: "HomeUITestSupport",
            targets: ["HomeUITestSupport"]
        ),
        .library(
            name: "HomeUIDI",
            targets: ["HomeUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Library/AsyncTesting"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Component/Home"),
        .package(path: "../../Component/Money"),
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
                .product(name: "AsyncTesting", package: "AsyncTesting"),
                .product(name: "HomeTestSupport", package: "Home"),
                .product(name: "ProductTestSupport", package: "Product"),
                "HomeUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Home", package: "Home"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/HomeUIAcceptanceTests"
        ),
        .target(
            name: "HomeUITestSupport",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                "HomeUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Home", package: "Home"),
                .product(name: "Money", package: "Money"),
                .product(name: "ProductUI", package: "ProductUI"),
            ],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "HomeUIUnitTests",
            dependencies: [
                .product(name: "AsyncTesting", package: "AsyncTesting"),
                .product(name: "HomeTestSupport", package: "Home"),
                .product(name: "ProductTestSupport", package: "Product"),
                "HomeUI",
                "HomeUITestSupport",
                .product(name: "Product", package: "Product"),
                .product(name: "Home", package: "Home"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/HomeUIUnitTests"
        ),
        .testTarget(
            name: "HomeUISnapshotTests",
            dependencies: [
                .product(name: "HomeTestSupport", package: "Home"),
                "HomeUI",
                "HomeUITestSupport",
                .product(name: "Product", package: "Product"),
                .product(name: "Home", package: "Home"),
                .product(name: "Money", package: "Money"),
                .product(name: "ProductUI", package: "ProductUI"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/HomeUISnapshotTests"
        )
    ]
)
