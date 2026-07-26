// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AccountUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "AccountUI",
            targets: ["AccountUI"]
        ),
        .library(
            name: "AccountUIDI",
            targets: ["AccountUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Session"),
        .package(path: "../AuthUI")
    ],
    targets: [
        .target(
            name: "AccountUI",
            dependencies: [
                .product(name: "Session", package: "Session")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI"]
        ),
        .target(
            name: "AccountUIDI",
            dependencies: [
                "AccountUI",
                .product(name: "Session", package: "Session"),
                .product(name: "AuthUIDI", package: "AuthUI")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "AccountUITests",
            dependencies: ["AccountUIDI"],
            path: "Tests/AccountUITests"
        )
    ]
)
