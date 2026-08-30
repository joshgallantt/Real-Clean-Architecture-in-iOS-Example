// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OrderUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "OrderUI",
            targets: ["OrderUI"]
        ),
        .library(
            name: "OrderUITestSupport",
            targets: ["OrderUITestSupport"]
        ),
        .library(
            name: "OrderUIDI",
            targets: ["OrderUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Library/AsyncTesting"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Order"),
        .package(path: "../../Component/Bag"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Component/Session"),
        .package(path: "../../Component/Money"),
        .package(path: "../AuthUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../SheetUI")
    ],
    targets: [
        .target(
            name: "OrderUI",
            dependencies: [
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI"]
        ),
        .target(
            name: "OrderUIDI",
            dependencies: [
                "OrderUI",
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "SheetUI", package: "SheetUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "OrderUIAcceptanceTests",
            dependencies: [
                .product(name: "MoneyTestSupport", package: "Money"),
                .product(name: "AsyncTesting", package: "AsyncTesting"),
                .product(name: "AuthUITestSupport", package: "AuthUI"),
                .product(name: "OrderTestSupport", package: "Order"),
                .product(name: "SessionTestSupport", package: "Session"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "BagTestSupport", package: "Bag"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                "OrderUI",
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/OrderUIAcceptanceTests"
        ),
        .target(
            name: "OrderUITestSupport",
            dependencies: [
                .product(name: "AsyncTesting", package: "AsyncTesting"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                "OrderUI",
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
            ],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "OrderUIUnitTests",
            dependencies: [
                .product(name: "MoneyTestSupport", package: "Money"),
                .product(name: "AsyncTesting", package: "AsyncTesting"),
                .product(name: "AuthUITestSupport", package: "AuthUI"),
                .product(name: "OrderTestSupport", package: "Order"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "BagTestSupport", package: "Bag"),
                .product(name: "SnackbarUITestSupport", package: "SnackbarUI"),
                "OrderUI",
                "OrderUITestSupport",
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/OrderUIUnitTests"
        ),
        .testTarget(
            name: "OrderUISnapshotTests",
            dependencies: [
                "OrderUI",
                "OrderUITestSupport",
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/OrderUISnapshotTests"
        )
    ]
)
