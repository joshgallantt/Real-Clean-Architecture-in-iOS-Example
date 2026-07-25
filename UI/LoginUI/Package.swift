// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LoginUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "LoginUI",
            targets: ["LoginUI"]
        ),
        .library(
            name: "LoginUIDI",
            targets: ["LoginUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Session"),
        .package(path: "../SheetUI")
    ],
    targets: [
        .target(
            name: "LoginUI",
            dependencies: [
                .product(name: "Session", package: "Session"),
                .product(name: "SheetUI", package: "SheetUI")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI", "Navigation"]
        ),
        .target(
            name: "LoginUIDI",
            dependencies: [
                "LoginUI",
                .product(name: "Session", package: "Session"),
                .product(name: "SheetUI", package: "SheetUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "LoginUITests",
            dependencies: ["LoginUIDI"],
            path: "Tests/LoginUITests"
        ),
    ]
)
