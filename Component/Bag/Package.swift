// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Bag",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Bag",
            targets: ["Bag"]
        ),
        .library(
            name: "BagData",
            targets: ["BagData"]
        ),
        .library(
            name: "BagTestSupport",
            targets: ["BagTestSupport"]
        ),
        .library(
            name: "BagDI",
            targets: ["BagDI"]
        )
    ],
    dependencies: [
        .package(path: "../Product"),
        .package(path: "../Session"),
        .package(path: "../Money")
    ],
    targets: [
        .target(
            name: "Bag",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Sources",
            exclude: ["DI", "Data", "TestSupport"],
            sources: ["Domain"]
        ),
        .target(
            name: "BagData",
            dependencies: [
                "Bag",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Sources",
            exclude: ["Domain", "DI", "TestSupport"],
            sources: ["Data"]
        ),
        .target(
            name: "BagTestSupport",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                "Bag",
                .product(name: "Product", package: "Product")
            ],
            path: "Sources/TestSupport"
        ),
        .target(
            name: "BagDI",
            dependencies: [
                "Bag",
                "BagData",
                .product(name: "Product", package: "Product"),
                .product(name: "Session", package: "Session")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "BagUnitTests",
            dependencies: [
                .product(name: "MoneyTestSupport", package: "Money"),
                .product(name: "ProductTestSupport", package: "Product"),
                "Bag",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/BagUnitTests"
        ),
        .testTarget(
            name: "BagAcceptanceTests",
            dependencies: [
                .product(name: "MoneyTestSupport", package: "Money"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SessionTestSupport", package: "Session"),
                "Bag",
                "BagDI",
                "BagData",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/BagAcceptanceTests"
        )
    ]
)
