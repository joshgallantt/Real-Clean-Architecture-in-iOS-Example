// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Session",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Session",
            targets: ["Session"]
        ),
        .library(
            name: "SessionData",
            targets: ["SessionData"]
        ),
        .library(
            name: "SessionDI",
            targets: ["SessionDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Library/Networking")
    ],
    targets: [
        .target(
            name: "Session",
            dependencies: [],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "SessionData",
            dependencies: [
                "Session",
                .product(name: "Networking", package: "Networking")
            ],
            path: "Sources",
            exclude: ["Domain", "DI"],
            sources: ["Data"]
        ),
        .target(
            name: "SessionDI",
            dependencies: ["Session", "SessionData"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "SessionTests",
            dependencies: ["SessionDI"],
            path: "Tests/SessionTests"
        ),
    ]
)
