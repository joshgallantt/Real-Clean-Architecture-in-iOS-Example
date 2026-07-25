// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AuthGate",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "AuthGate",
            targets: ["AuthGate"]
        )
    ],
    targets: [
        .target(
            name: "AuthGate",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "AuthGateTests",
            dependencies: ["AuthGate"],
            path: "Tests/AuthGateTests"
        ),
    ]
)
