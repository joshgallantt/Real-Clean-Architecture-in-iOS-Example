// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BagUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "BagUI",
            targets: ["BagUI"]
        ),
        .library(
            name: "BagUITestSupport",
            targets: ["BagUITestSupport"]
        ),
        .library(
            name: "BagUIDI",
            targets: ["BagUIDI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Bag"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Component/Money"),
        .package(path: "../OrderUI"),
        .package(path: "../ProductActionsUI"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "BagUI",
            dependencies: [
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI", "Navigation"]
        ),
        .target(
            name: "BagUIDI",
            dependencies: [
                "BagUI",
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "OrderUIDI", package: "OrderUI"),
                .product(name: "ProductActionsUIDI", package: "ProductActionsUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "BagUIAcceptanceTests",
            dependencies: [
                .product(name: "MoneyTestSupport", package: "Money"),
                .product(name: "BagTestSupport", package: "Bag"),
                .product(name: "ProductTestSupport", package: "Product"),
                "BagUI",
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/BagUIAcceptanceTests"
        ),
        .target(
            name: "BagUITestSupport",
            dependencies: [
                .product(name: "MoneyTestSupport", package: "Money"),
                .product(name: "ProductTestSupport", package: "Product"),
                "BagUI",
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "BagUIUnitTests",
            dependencies: [
                .product(name: "MoneyTestSupport", package: "Money"),
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "BagTestSupport", package: "Bag"),
                "BagUI",
                "BagUITestSupport",
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/BagUIUnitTests"
        ),
        .testTarget(
            name: "BagUISnapshotTests",
            dependencies: [
                .product(name: "BagTestSupport", package: "Bag"),
                "BagUI",
                "BagUITestSupport",
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/BagUISnapshotTests"
        )
    ]
)
