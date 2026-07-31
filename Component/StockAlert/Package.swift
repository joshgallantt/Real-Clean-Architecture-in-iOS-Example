// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StockAlert",
    platforms: [
        .iOS(.v26)
    ],
    products: [
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
        .package(path: "../../Library/Money")
    ],
    targets: [
        .target(
            name: "StockAlert",
            dependencies: [
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["DI", "Data"],
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
            exclude: ["Domain", "DI"],
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
            name: "StockAlertAcceptanceTests",
            dependencies: [
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
