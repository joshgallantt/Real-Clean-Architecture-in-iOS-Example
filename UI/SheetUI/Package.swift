// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SheetUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
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
            name: "SheetUI",
            dependencies: [],
            path: "Sources/SheetUI"
        ),
        .target(
            name: "SheetUIDI",
            dependencies: ["SheetUI"],
            path: "Sources",
            exclude: ["SheetUI"],
            sources: ["SheetUIHost", "SheetUIDI"]
        )
    ]
)
