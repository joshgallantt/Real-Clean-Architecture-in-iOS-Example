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
        .package(path: "../BagUI"),
        .package(path: "../SharedUI"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "ProductUI",
            dependencies: [
                .product(name: "Product", package: "Product"),
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
                .product(name: "BagUIDI", package: "BagUI"),
                .product(name: "SharedUIDI", package: "SharedUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "ProductUITests",
            dependencies: ["ProductUIDI"],
            path: "Tests/ProductUITests"
        )
    ]
)
