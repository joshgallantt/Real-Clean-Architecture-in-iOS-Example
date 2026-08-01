// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OrderUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "OrderUI",
            targets: ["OrderUI"]
        ),
        .library(
            name: "OrderUIDI",
            targets: ["OrderUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Order"),
        .package(path: "../../Component/Bag"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Component/Session"),
        .package(path: "../../Library/Money"),
        .package(path: "../AuthUI"),
        .package(path: "../SnackbarUI"),
        .package(path: "../SheetUI")
    ],
    targets: [
        .target(
            name: "OrderUI",
            dependencies: [
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI"]
        ),
        .target(
            name: "OrderUIDI",
            dependencies: [
                "OrderUI",
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI"),
                .product(name: "SheetUI", package: "SheetUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "OrderUIAcceptanceTests",
            dependencies: [
                "OrderUI",
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "Session", package: "Session"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/OrderUIAcceptanceTests"
        ),
        .testTarget(
            name: "OrderUIUnitTests",
            dependencies: [
                "OrderUI",
                .product(name: "Order", package: "Order"),
                .product(name: "Bag", package: "Bag"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Tests/OrderUIUnitTests"
        )
    ]
)
