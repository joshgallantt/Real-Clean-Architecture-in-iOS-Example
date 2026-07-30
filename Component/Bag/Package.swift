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
        .package(path: "../Session")
    ],
    targets: [
        .target(
            name: "Bag",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Session", package: "Session")
            ],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "BagData",
            dependencies: [
                "Bag",
                .product(name: "Session", package: "Session")
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
            name: "BagTests",
            dependencies: [
                "Bag",
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/BagTests"
        ),
        .testTarget(
            name: "BagDataTests",
            dependencies: ["BagData"],
            path: "Tests/BagDataTests"
        ),
        .testTarget(
            name: "BagAcceptanceTests",
            dependencies: [
                "BagDI",
                .product(name: "Session", package: "Session")
            ],
            path: "Tests/BagAcceptanceTests"
        )
    ]
)
