// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TrackingUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "TrackingUI",
            targets: ["TrackingUI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Tracking"),
        .package(path: "../../Component/Product"),
        .package(path: "../../Component/Money")
    ],
    targets: [
        .target(
            name: "TrackingUI",
            dependencies: [
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Sources/TrackingUI"
        ),
        .testTarget(
            name: "TrackingUIUnitTests",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                "TrackingUI",
                .product(name: "Tracking", package: "Tracking"),
                .product(name: "Product", package: "Product"),
                .product(name: "Money", package: "Money")
            ],
            path: "Tests/TrackingUIUnitTests"
        )
    ]
)
