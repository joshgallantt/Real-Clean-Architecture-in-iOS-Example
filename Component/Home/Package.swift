// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Home",
    platforms: [
        .iOS(.v26)
    ],
    products: [
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
        .package(path: "../../Library/Money")
    ],
    targets: [
        .target(
            name: "Home",
            dependencies: [
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["DI"],
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
                "Home",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/HomeUnitTests"
        ),
        .testTarget(
            name: "HomeAcceptanceTests",
            dependencies: [
                "HomeDI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/HomeAcceptanceTests"
        )
    ]
)
