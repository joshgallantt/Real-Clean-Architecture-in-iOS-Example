// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Order",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Order",
            targets: ["Order"]
        ),
        .library(
            name: "OrderData",
            targets: ["OrderData"]
        ),
        .library(
            name: "OrderDI",
            targets: ["OrderDI"]
        )
    ],
    dependencies: [
        .package(path: "../Product"),
        .package(path: "../Session"),
        .package(path: "../Money")
    ],
    targets: [
        .target(
            name: "Order",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Session", package: "Session"),
                .product(name: "Money", package: "Money")
            ],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "OrderData",
            dependencies: [
                "Order",
                .product(name: "Product", package: "Product"),
                .product(name: "Session", package: "Session"),
                .product(name: "Money", package: "Money")
            ],
            path: "Sources",
            exclude: ["Domain", "DI"],
            sources: ["Data"]
        ),
        .target(
            name: "OrderDI",
            dependencies: [
                "Order",
                "OrderData",
                .product(name: "Session", package: "Session")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "OrderUnitTests",
            dependencies: [
                "Order",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/OrderUnitTests"
        ),
        .testTarget(
            name: "OrderAcceptanceTests",
            dependencies: [
                "OrderDI",
                "OrderData",
                .product(name: "Product", package: "Product"),
                .product(name: "Session", package: "Session"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/OrderAcceptanceTests"
        )
    ]
)
