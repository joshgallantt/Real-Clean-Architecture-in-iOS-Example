// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SheetUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SheetUITestSupport",
            targets: ["SheetUITestSupport"]
        ),
        .library(
            name: "SheetUI",
            targets: ["SheetUI"]
        ),
        .library(
            name: "SheetUIDI",
            targets: ["SheetUIDI"]
        )
    ],
    targets: [
        .target(
            name: "SheetUITestSupport",
            dependencies: [
                "SheetUI"
            ],
            path: "Sources/TestSupport"
        ),
        .target(
            name: "SheetUI",
            dependencies: [],
            path: "Sources/SheetUI"
        ),
        .target(
            name: "SheetUIDI",
            dependencies: ["SheetUI"],
            path: "Sources",
            exclude: ["SheetUI", "TestSupport"],
            sources: ["SheetUIHost", "SheetUIDI"]
        )
    ]
)
