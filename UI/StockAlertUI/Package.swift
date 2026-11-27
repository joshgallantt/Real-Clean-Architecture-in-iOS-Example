// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StockAlertUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "StockAlertUI",
            targets: ["StockAlertUI"]
        ),
        .library(
            name: "StockAlertUITestSupport",
            targets: ["StockAlertUITestSupport"]
        ),
        .library(
            name: "StockAlertUIDI",
            targets: ["StockAlertUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../TrackingUI"),
        .package(path: "../../Component/Tracking"),
        .package(path: "../../Component/StockAlert"),
        .package(path: "../../Component/Product"),
        .package(path: "../ProductUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../ProductActionsUI")
    ],
    targets: [
        .target(
            name: "StockAlertUI",
            dependencies: [
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "TrackingUI", package: "TrackingUI"),
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "ProductUI", package: "ProductUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI", "Navigation"]
        ),
        .target(
            name: "StockAlertUIDI",
            dependencies: [
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "TrackingUI", package: "TrackingUI"),
                "StockAlertUI",
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "ProductActionsUIDI", package: "ProductActionsUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "StockAlertUIAcceptanceTests",
            dependencies: [
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "TrackingTestSupport", package: "Tracking"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                .product(name: "StockAlertTestSupport", package: "StockAlert"),
                "StockAlertUITestSupport",
                "StockAlertUI",
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/StockAlertUIAcceptanceTests"
        ),
        .target(
            name: "StockAlertUITestSupport",
            dependencies: [
                "StockAlertUI",
                .product(name: "Product", package: "Product")
            ],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "StockAlertUIUnitTests",
            dependencies: [
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "TrackingTestSupport", package: "Tracking"),
                .product(name: "TrackingUI", package: "TrackingUI"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                .product(name: "StockAlertTestSupport", package: "StockAlert"),
                "StockAlertUITestSupport",
                "StockAlertUI",
                .product(name: "StockAlert", package: "StockAlert"),
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/StockAlertUIUnitTests"
        )
    ]
)
