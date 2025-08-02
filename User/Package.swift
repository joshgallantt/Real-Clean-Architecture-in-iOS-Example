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
            name: "UserDI",
            targets: ["UserDI"]
        )
    ],
    targets: [
        .target(
            name: "UserDomain",
            dependencies: [],
            path: "Sources/Domain"
        ),
        .target(
            name: "UserData",
            dependencies: ["UserDomain"],
            path: "Sources/Data"
        ),
        .target(
            name: "UserDI",
            dependencies: ["UserDomain", "UserData"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "UserTests",
            dependencies: ["UserDI"],
            path: "Tests/UserTests"
        ),
    ]
)
