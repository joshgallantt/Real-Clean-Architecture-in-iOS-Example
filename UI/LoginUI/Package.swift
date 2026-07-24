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
        .package(path: "../../Component/Session")
    ],
    targets: [
        .target(
            name: "LoginUI",
            dependencies: [
                .product(name: "Session", package: "Session")
            ],
            path: "Sources/UI"
        ),
        .target(
            name: "LoginUIDI",
            dependencies: [
                "LoginUI",
                .product(name: "Session", package: "Session")
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
