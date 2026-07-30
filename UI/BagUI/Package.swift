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
            name: "BagUIDI",
            targets: ["BagUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Bag"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Library/Money"),
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
                .product(name: "Money", package: "Money")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "BagUIAcceptanceTests",
            dependencies: [
                "BagUI",
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/BagUIAcceptanceTests"
        )
    ]
)
