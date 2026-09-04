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
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Component/Money"),
        .package(path: "../OrderUI"),
        .package(path: "../ProductActionsUI"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "ProductUI",
            dependencies: [
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI"]
        ),
        .target(
            name: "ProductUIDI",
            dependencies: [
                "ProductUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "OrderUIDI", package: "OrderUI"),
                .product(name: "ProductActionsUIDI", package: "ProductActionsUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "ProductUIUnitTests",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                "ProductUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/ProductUIUnitTests"
        ),
        .testTarget(
            name: "ProductUISnapshotTests",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                "ProductUI",
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/ProductUISnapshotTests"
        )
    ]
)
