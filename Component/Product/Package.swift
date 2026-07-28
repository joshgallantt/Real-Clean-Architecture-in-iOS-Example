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
        .package(path: "../../Library/Networking")
    ],
    targets: [
        .target(
            name: "Product",
            dependencies: [],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "ProductData",
            dependencies: [
                "Product",
                .product(name: "Networking", package: "Networking")
            ],
            path: "Sources",
            exclude: ["Domain", "DI"],
            sources: ["Data"]
        ),
        .target(
            name: "ProductDI",
            dependencies: ["Product", "ProductData"],
            path: "Sources/DI"
        )
    ]
)
