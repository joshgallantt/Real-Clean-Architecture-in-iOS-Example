// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AccountUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "AccountUI",
            targets: ["AccountUI"]
        ),
        .library(
            name: "AccountUITestSupport",
            targets: ["AccountUITestSupport"]
        ),
        .library(
            name: "AccountUIDI",
            targets: ["AccountUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Component/Product"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Session"),
        .package(path: "../AuthUI")
    ],
    targets: [
        .target(
            name: "AccountUI",
            dependencies: [
                .product(name: "Session", package: "Session")
            ],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI", "Navigation"]
        ),
        .target(
            name: "AccountUIDI",
            dependencies: [
                "AccountUI",
                .product(name: "Session", package: "Session"),
                .product(name: "AuthUIDI", package: "AuthUI")
            ],
            path: "Sources/DI"
        ),
        .target(
            name: "AccountUITestSupport",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SessionTestSupport", package: "Session"),
                "AccountUI",
                .product(name: "Session", package: "Session"),
            ],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "AccountUIUnitTests",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                "AccountUITestSupport",
                .product(name: "SessionTestSupport", package: "Session"),
                "AccountUI",
                .product(name: "Session", package: "Session")
            ],
            path: "Tests/AccountUIUnitTests"
        ),
        .testTarget(
            name: "AccountUISnapshotTests",
            dependencies: [
                .product(name: "SessionTestSupport", package: "Session"),
                "AccountUI",
                "AccountUITestSupport",
                .product(name: "Session", package: "Session"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/AccountUISnapshotTests"
        )
    ]
)
