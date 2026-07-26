// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Session",
    platforms: [
        .iOS(.v26)
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
                "Session"
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
        )
    ]
)
