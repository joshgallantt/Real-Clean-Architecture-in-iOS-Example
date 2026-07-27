// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SharedUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SharedUI",
            targets: ["SharedUI"]
        ),
        .library(
            name: "SharedUIDI",
            targets: ["SharedUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Wishlist"),
        .package(path: "../AuthUI"),
        .package(path: "../SnackbarUI")
    ],
    targets: [
        .target(
            name: "SharedUI",
            dependencies: [
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI"]
        ),
        .target(
            name: "SharedUIDI",
            dependencies: [
                "SharedUI",
                .product(name: "Wishlist", package: "Wishlist"),
                .product(name: "AuthUI", package: "AuthUI"),
                .product(name: "SnackbarUI", package: "SnackbarUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "SharedUITests",
            dependencies: ["SharedUIDI"],
            path: "Tests/SharedUITests"
        )
    ]
)
