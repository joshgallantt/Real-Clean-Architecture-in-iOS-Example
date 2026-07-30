// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Money",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Money",
            targets: ["Money"]
        )
    ],
    targets: [
        .target(
            name: "Money",
            dependencies: [],
            path: "Sources/Money"
        ),
        .testTarget(
            name: "MoneyTests",
            dependencies: ["Money"],
            path: "Tests/MoneyTests"
        )
    ]
)
