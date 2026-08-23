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
            name: "WishlistUITestSupport",
            targets: ["WishlistUITestSupport"]
        ),
        .library(
            name: "WishlistUIDI",
            targets: ["WishlistUIDI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Wishlist"),
        .package(path: "../../Component/StockAlert"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Component/Money"),
        .package(path: "../../Component/Session"),
        .package(path: "../ProductUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../AuthUI"),
        .package(path: "../ProductActionsUI")
    ],
    targets: [
        .target(
            name: "WishlistUI",
            dependencies: [
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "StockAlert", package: "StockAlert"),
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
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "ProductActionsUIDI", package: "ProductActionsUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "WishlistUIAcceptanceTests",
            dependencies: [
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                "WishlistUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/WishlistUIAcceptanceTests"
        ),
        .target(
            name: "WishlistUITestSupport",
            dependencies: [
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                .product(name: "SessionTestSupport", package: "Session"),
                "WishlistUI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "ProductUI", package: "ProductUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "AuthUI", package: "AuthUI"),
            ],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "WishlistUIUnitTests",
            dependencies: [
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                "WishlistUITestSupport",
                .product(name: "SessionTestSupport", package: "Session"),
                "WishlistUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/WishlistUIUnitTests"
        ),
        .testTarget(
            name: "WishlistUISnapshotTests",
            dependencies: [
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                "WishlistUI",
                "WishlistUITestSupport",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "ProductUI", package: "ProductUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/WishlistUISnapshotTests"
        )
    ]
)
