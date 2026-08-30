// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Home",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "HomeTestSupport",
            targets: ["HomeTestSupport"]
        ),
        .library(
            name: "Home",
            targets: ["Home"]
        ),
        .library(
            name: "HomeDI",
            targets: ["HomeDI"]
        )
    ],
    dependencies: [
        .package(path: "../Product"),
        .package(path: "../Money")
    ],
    targets: [
        .target(
            name: "HomeTestSupport",
            dependencies: [
                "Home"
            ],
            path: "Sources/TestSupport"
        ),
        .target(
            name: "Home",
            dependencies: [
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["DI", "TestSupport"],
            sources: ["Domain"]
        ),
        .target(
            name: "HomeDI",
            dependencies: [
                "Home",
                .product(name: "Product", package: "Product")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "HomeUnitTests",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                "Home",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/HomeUnitTests"
        ),
        .testTarget(
            name: "HomeAcceptanceTests",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                "Home",
                "HomeDI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/HomeAcceptanceTests"
        )
    ]
)
