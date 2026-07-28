// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Search",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Search",
            targets: ["Search"]
        ),
        .library(
            name: "SearchData",
            targets: ["SearchData"]
        ),
        .library(
            name: "SearchDI",
            targets: ["SearchDI"]
        )
    ],
    dependencies: [
        .package(path: "../Session")
    ],
    targets: [
        .target(
            name: "Search",
            dependencies: [],
            path: "Sources",
            exclude: ["DI", "Data"],
            sources: ["Domain"]
        ),
        .target(
            name: "SearchData",
            dependencies: [
                "Search",
                .product(name: "Session", package: "Session")
            ],
            path: "Sources",
            exclude: ["Domain", "DI"],
            sources: ["Data"]
        ),
        .target(
            name: "SearchDI",
            dependencies: [
                "Search",
                "SearchData",
                .product(name: "Session", package: "Session")
            ],
            path: "Sources/DI"
        )
    ]
)
