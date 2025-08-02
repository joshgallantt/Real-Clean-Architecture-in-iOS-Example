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
        .package(name: "UserDI", path: "../User")
    ],
    targets: [
        .target(
            name: "LoginUI",
            dependencies: [
                .product(name: "UserDI", package: "UserDI")
            ],
            path: "Sources/UI"
        ),
        .target(
            name: "LoginUIDI",
            dependencies: [
                "LoginUI",
                .product(name: "UserDI", package: "UserDI")
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
