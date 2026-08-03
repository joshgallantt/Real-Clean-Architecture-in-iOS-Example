// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Product",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Product",
            targets: ["Product"]
        ),
        .library(
            name: "ProductData",
            targets: ["ProductData"]
        ),
        .library(
            name: "ProductDI",
            targets: ["ProductDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Library/Networking"),
        .package(path: "../Money")
    ],
    targets: [
        .target(
            name: "Product",
            dependencies: [
                .product(name: "Money", package: "Money")
            ],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "ProductData",
            dependencies: [
                "Product",
                .product(name: "Networking", package: "Networking"),
                .product(name: "Money", package: "Money")
            ],
            path: "Sources",
            exclude: ["Domain", "DI"],
            sources: ["Data"]
        ),
        .target(
            name: "ProductDI",
            dependencies: ["Product", "ProductData"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "ProductUnitTests",
            dependencies: ["Product"],
            path: "Tests/ProductUnitTests"
        ),
        .testTarget(
            name: "ProductAcceptanceTests",
            dependencies: [
                "ProductDI",
                "ProductData",
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/ProductAcceptanceTests"
        )
    ]
)
