// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "User",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "User",
            targets: ["User"]
        ),
        .library(
            name: "UserData",
            targets: ["UserData"]
        ),
        .library(
            name: "UserDI",
            targets: ["UserDI"]
        )
    ],
    targets: [
        .target(
            name: "User",
            dependencies: [],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "UserData",
            dependencies: ["User"],
            path: "Sources",
            exclude: ["Domain", "DI"],
            sources: ["Data"]
        ),
        .target(
            name: "UserDI",
            dependencies: ["User", "UserData"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "UserTests",
            dependencies: ["UserDI"],
            path: "Tests/UserTests"
        ),
    ]
)

