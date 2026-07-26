// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AuthUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "AuthUI",
            targets: ["AuthUI"]
        ),
        .library(
            name: "AuthUIDI",
            targets: ["AuthUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Session"),
        .package(path: "../SheetUI")
    ],
    targets: [
        .target(
            name: "AuthUI",
            dependencies: [],
            path: "Sources/AuthUI"
        ),
        .target(
            name: "AuthUIDI",
            dependencies: [
                "AuthUI",
                .product(name: "Session", package: "Session"),
                .product(name: "SheetUI", package: "SheetUI")
            ],
            path: "Sources",
            exclude: ["AuthUI"],
            sources: ["AuthUIHost", "AuthUIDI"]
        ),
    ]
)
