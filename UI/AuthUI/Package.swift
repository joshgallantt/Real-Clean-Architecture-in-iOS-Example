// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AuthUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "AuthUI",
            targets: ["AuthUI"]
        ),
        .library(
            name: "AuthUITestSupport",
            targets: ["AuthUITestSupport"]
        ),
        .library(
            name: "AuthUIDI",
            targets: ["AuthUIDI"]
        )
    ],
    dependencies: [
        .package(path: "../../Library/AsyncTesting"),
        .package(path: "../../Component/Product"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"),
        .package(path: "../../Component/Session"),
        .package(path: "../SheetUI")
    ],
    targets: [
        .target(
            name: "AuthUI",
            dependencies: [],
            path: "Sources/AuthUI"
        ),
        .target(
            name: "AuthUIDI",
            dependencies: [
                "AuthUI",
                .product(name: "Session", package: "Session"),
                .product(name: "SheetUI", package: "SheetUI")
            ],
            path: "Sources",
            exclude: ["AuthUI"],
            sources: ["AuthUIHost", "AuthUIDI"]
        ),
        .target(
            name: "AuthUITestSupport",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                "AuthUIDI",
                .product(name: "Session", package: "Session"),
                .product(name: "SessionTestSupport", package: "Session"),
                .product(name: "SheetUI", package: "SheetUI"),
                "AuthUI",
            ],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "AuthUIUnitTests",
            dependencies: [
                .product(name: "AsyncTesting", package: "AsyncTesting"),
                .product(name: "SheetUITestSupport", package: "SheetUI"),
                .product(name: "ProductTestSupport", package: "Product"),
                "AuthUITestSupport",
                .product(name: "SessionTestSupport", package: "Session"),
                "AuthUIDI",
                .product(name: "Session", package: "Session"),
                .product(name: "SheetUI", package: "SheetUI")
            ],
            path: "Tests/AuthUIUnitTests"
        ),
        .testTarget(
            name: "AuthUISnapshotTests",
            dependencies: [
                .product(name: "SheetUITestSupport", package: "SheetUI"),
                .product(name: "Session", package: "Session"),
                "AuthUIDI",
                .product(name: "SessionTestSupport", package: "Session"),
                "AuthUI",
                "AuthUITestSupport",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/AuthUISnapshotTests"
        )
    ]
)
