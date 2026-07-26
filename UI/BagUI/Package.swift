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
        .package(path: "../../Component/Session"),
        .package(path: "../SnackbarUI")
    ],
    targets: [
        .target(
            name: "BagUI",
            dependencies: [
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Session", package: "Session"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
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
                .product(name: "Session", package: "Session"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "BagUITests",
            dependencies: ["BagUIDI"],
            path: "Tests/BagUITests"
        )
    ]
)
