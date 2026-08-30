// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StockAlert",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "StockAlertTestSupport",
            targets: ["StockAlertTestSupport"]
        ),
        .library(
            name: "StockAlert",
            targets: ["StockAlert"]
        ),
        .library(
            name: "StockAlertData",
            targets: ["StockAlertData"]
        ),
        .library(
            name: "StockAlertDI",
            targets: ["StockAlertDI"]
        )
    ],
    dependencies: [
        .package(path: "../Session"),
        .package(path: "../Product"),
        .package(path: "../Money")
    ],
    targets: [
        .target(
            name: "StockAlertTestSupport",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Session", package: "Session"),
                "StockAlert"
            ],
            path: "Sources/TestSupport"
        ),
        .target(
            name: "StockAlert",
            dependencies: [
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["DI", "Data", "TestSupport"],
            sources: ["Domain"]
        ),
        .target(
            name: "StockAlertData",
            dependencies: [
                "StockAlert",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["Domain", "DI", "TestSupport"],
            sources: ["Data"]
        ),
        .target(
            name: "StockAlertDI",
            dependencies: [
                "StockAlert",
                "StockAlertData",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "StockAlertUnitTests",
            dependencies: [
                "StockAlert",
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/StockAlertUnitTests"
        ),
        .testTarget(
            name: "StockAlertAcceptanceTests",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SessionTestSupport", package: "Session"),
                "StockAlert",
                "StockAlertDI",
                "StockAlertData",
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/StockAlertAcceptanceTests"
        )
    ]
)
