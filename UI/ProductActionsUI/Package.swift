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
            name: "ProductActionsUITestSupport",
            targets: ["ProductActionsUITestSupport"]
        ),
        .library(
            name: "ProductActionsUIDI",
            targets: ["ProductActionsUIDI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Wishlist"),
        .package(path: "../../Component/Bag"),
        .package(path: "../../Component/StockAlert"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Component/Money"),
        .package(path: "../../Component/Session"),
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
                .product(name: "AuthUITestSupport", package: "AuthUI"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                .product(name: "StockAlertTestSupport", package: "StockAlert"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "BagTestSupport", package: "Bag"),
                "ProductActionsUI",
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                "ProductActionsUIDI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                "ProductActionsUITestSupport"
            ],
            path: "Tests/ProductActionsUIAcceptanceTests"
        ),
        .target(
            name: "ProductActionsUITestSupport",
            dependencies: [
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                .product(name: "Money", package: "Money"),
                "ProductActionsUI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
            ],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "ProductActionsUIUnitTests",
            dependencies: [
                .product(name: "AuthUITestSupport", package: "AuthUI"),
                .product(name: "WishlistTestSupport", package: "Wishlist"),
                .product(name: "StockAlertTestSupport", package: "StockAlert"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "BagTestSupport", package: "Bag"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                "ProductActionsUI",
                "ProductActionsUITestSupport",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/ProductActionsUIUnitTests"
        ),
        .testTarget(
            name: "ProductActionsUISnapshotTests",
            dependencies: [
                .product(name: "BagTestSupport", package: "Bag"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                .product(name: "Money", package: "Money"),
                "ProductActionsUI",
                "ProductActionsUITestSupport",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/ProductActionsUISnapshotTests"
        )
    ]
)
