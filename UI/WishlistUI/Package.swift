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
        .package(path: "../TrackingUI"),
        .package(path: "../../Component/Tracking"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Wishlist"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Component/Money"),
        .package(path: "../../Component/Session"),
        .package(path: "../../Component/Settings"),
        .package(path: "../ProductUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../AuthUI"),
        .package(path: "../ProductActionsUI"),
        .package(path: "../StockAlertUI")
    ],
    targets: [
        .target(
            name: "WishlistUI",
            dependencies: [
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "TrackingUI", package: "TrackingUI"),
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "Settings", package: "Settings"),
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
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "TrackingUI", package: "TrackingUI"),
                "WishlistUI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "Settings", package: "Settings"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "ProductActionsUIDI", package: "ProductActionsUI"),
                .product(name: "StockAlertUIDI", package: "StockAlertUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "WishlistUIAcceptanceTests",
            dependencies: [
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "TrackingTestSupport", package: "Tracking"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                .product(name: "WishlistTestSupport", package: "Wishlist"),
                "WishlistUITestSupport",
                "WishlistUI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/WishlistUIAcceptanceTests"
        ),
        .target(
            name: "WishlistUITestSupport",
            dependencies: [
                "WishlistUI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Product", package: "Product"),
                .product(name: "Session", package: "Session"),
                .product(name: "ProductUI", package: "ProductUI"),
                .product(name: "AuthUI", package: "AuthUI"),
            ],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "WishlistUIUnitTests",
            dependencies: [
                .product(name: "AuthUITestSupport", package: "AuthUI"),
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "TrackingTestSupport", package: "Tracking"),
                .product(name: "TrackingUI", package: "TrackingUI"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                .product(name: "WishlistTestSupport", package: "Wishlist"),
                "WishlistUITestSupport",
                .product(name: "SessionTestSupport", package: "Session"),
                .product(name: "SettingsTestSupport", package: "Settings"),
                "WishlistUI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "Settings", package: "Settings"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/WishlistUIUnitTests"
        ),
        .testTarget(
            name: "WishlistUISnapshotTests",
            dependencies: [
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "TrackingTestSupport", package: "Tracking"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                .product(name: "WishlistTestSupport", package: "Wishlist"),
                "WishlistUITestSupport",
                "WishlistUI",
                .product(name: "Wishlist", package: "Wishlist"),
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
