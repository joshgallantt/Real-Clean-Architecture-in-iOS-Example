// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SearchHistory",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SearchHistory",
            targets: ["SearchHistory"]
        ),
        .library(
            name: "SearchHistoryData",
            targets: ["SearchHistoryData"]
        ),
        .library(
            name: "SearchHistoryDI",
            targets: ["SearchHistoryDI"]
        )
    ],
    dependencies: [
        .package(path: "../Session"),
        .package(path: "../Product")
    ],
    targets: [
        .target(
            name: "SearchHistory",
            dependencies: [
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "SearchHistoryData",
            dependencies: [
                "SearchHistory",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources",
            exclude: ["Domain", "DI"],
            sources: ["Data"]
        ),
        .target(
            name: "SearchHistoryDI",
            dependencies: [
                "SearchHistory",
                "SearchHistoryData",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "SearchHistoryTests",
            dependencies: [
                "SearchHistory",
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/SearchHistoryTests"
        ),
        .testTarget(
            name: "SearchHistoryAcceptanceTests",
            dependencies: [
                "SearchHistoryDI",
                .product(name: "Session", package: "Session"),
                .product(name: "Product", package: "Product")
            ],
            path: "Tests/SearchHistoryAcceptanceTests"
        )
    ]
)
