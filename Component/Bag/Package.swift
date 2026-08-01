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
            name: "BagDI",
            targets: ["BagDI"]
        )
    ],
    dependencies: [
        .package(path: "../Product"),
        .package(path: "../Session"),
        .package(path: "../../Library/Money")
    ],
    targets: [
        .target(
            name: "Bag",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Sources",
            exclude: ["DI", "Data"],
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
            exclude: ["Domain", "DI"],
            sources: ["Data"]
        ),
        .target(
            name: "BagDI",
            dependencies: [
                "Bag",
                "BagData",
                .product(name: "Session", package: "Session")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "BagUnitTests",
            dependencies: [
                "Bag",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/BagUnitTests"
        ),
        .testTarget(
            name: "BagAcceptanceTests",
            dependencies: [
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
