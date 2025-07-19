// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LoginUI",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "LoginPresentation",
            targets: ["LoginPresentation"]
        ),
        .library(
            name: "LoginUIDI",
            targets: ["LoginUIDI"]
        ),
    ],
    dependencies: [
        .package(name: "User", path: "../User")
    ],
    targets: [
        .target(
            name: "LoginPresentation",
            dependencies: [
                .product(name: "UserDomain", package: "User")
            ],
            path: "Sources/Presentation"
        ),
        .target(
            name: "LoginUIDI",
            dependencies: ["LoginPresentation"],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "LoginUITests",
            dependencies: ["LoginUIDI"],
            path: "Tests/LoginUITests"
        ),
    ]
)
