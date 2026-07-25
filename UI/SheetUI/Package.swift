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
        )
    ],
    targets: [
        .target(
            name: "SheetUI",
            dependencies: []
        )
    ]
)
