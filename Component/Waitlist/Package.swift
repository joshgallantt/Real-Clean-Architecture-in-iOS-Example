// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Waitlist",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "WaitlistTestSupport",
            targets: ["WaitlistTestSupport"]
        ),
        .library(
            name: "Waitlist",
            targets: ["Waitlist"]
        ),
        .library(
            name: "WaitlistData",
            targets: ["WaitlistData"]
        ),
        .library(
            name: "WaitlistDI",
            targets: ["WaitlistDI"]
        )
    ],
    dependencies: [
        .package(path: "../Session"),
        .package(path: "../Product")
    ],
    targets: [
        .target(
            name: "WaitlistTestSupport",
            dependencies: [
                .product(name: "Product", package: "Product"),
                "Waitlist"
            ],
            path: "Sources/TestSupport"
        ),
        .target(
            name: "Waitlist",
            dependencies: [
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["DI", "Data", "TestSupport"],
            sources: ["Domain"]
        ),
        .target(
            name: "WaitlistData",
            dependencies: [
                "Waitlist",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["Domain", "DI", "TestSupport"],
            sources: ["Data"]
        ),
        .target(
            name: "WaitlistDI",
            dependencies: [
                "Waitlist",
                "WaitlistData",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "WaitlistUnitTests",
            dependencies: [
                "Waitlist",
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/WaitlistUnitTests"
        ),
        .testTarget(
            name: "WaitlistAcceptanceTests",
            dependencies: [
                .product(name: "ProductTestSupport", package: "Product"),
                .product(name: "SessionTestSupport", package: "Session"),
                "Waitlist",
                "WaitlistDI",
                "WaitlistData",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/WaitlistAcceptanceTests"
        )
    ]
)
