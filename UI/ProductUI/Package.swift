// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ProductUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "ProductUI",
            targets: ["ProductUI"]
        ),
        .library(
            name: "ProductUIDI",
            targets: ["ProductUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Product")
    ],
    targets: [
        .target(
            name: "ProductUI",
            dependencies: [
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI"]
        ),
        .target(
            name: "ProductUIDI",
            dependencies: [
                "ProductUI",
                .product(name: "Product", package: "Product")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "ProductUITests",
            dependencies: ["ProductUIDI"],
            path: "Tests/ProductUITests"
        ),
    ]
)
