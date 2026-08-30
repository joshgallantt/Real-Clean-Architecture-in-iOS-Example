// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AsyncTesting",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "AsyncTesting",
            targets: ["AsyncTesting"]
        )
    ],
    targets: [
        .target(
            name: "AsyncTesting",
            dependencies: [],
            path: "Sources/AsyncTesting"
        )
    ]
)
