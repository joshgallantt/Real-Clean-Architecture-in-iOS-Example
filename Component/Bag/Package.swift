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
        .package(path: "../Session")
    ],
    targets: [
        .target(
            name: "Bag",
            dependencies: [
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
            dependencies: ["BagDI"],
            path: "Tests/BagTests"
        )
    ]
)
