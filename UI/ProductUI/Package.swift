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
        .package(path: "../../Component/Product"),
        .package(path: "../../Library/Money"),
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
                .product(name: "ProductActionsUIDI", package: "ProductActionsUI")
            ],
            path: "Sources/DI"
        )
    ]
)
