// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LoginUI",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "LoginUIDI",
            targets: ["LoginUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../User")
    ],
    targets: [
        .target(
            name: "LoginUI",
            dependencies: [
                .product(name: "User", package: "User")
            ],
            path: "Sources/UI"
        ),
        .target(
            name: "LoginUIDI",
            dependencies: [
                "LoginUI",
                .product(name: "UserDI", package: "User")
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
