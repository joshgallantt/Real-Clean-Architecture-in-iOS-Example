// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Session",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Session",
            targets: ["Session"]
        ),
        .library(
            name: "SessionData",
            targets: ["SessionData"]
        ),
        .library(
            name: "SessionTestSupport",
            targets: ["SessionTestSupport"]
        ),
        .library(
            name: "SessionDI",
            targets: ["SessionDI"]
        )
    ],
    targets: [
        .target(
            name: "Session",
            dependencies: [],
            path: "Sources",
            exclude: ["DI", "Data", "TestSupport"],
            sources: ["Domain"]
        ),
        .target(
            name: "SessionData",
            dependencies: [
                "Session"
            ],
            path: "Sources",
            exclude: ["Domain", "DI", "TestSupport"],
            sources: ["Data"]
        ),
        .target(
            name: "SessionDI",
            dependencies: ["Session", "SessionData"],
            path: "Sources/DI"
        ),
        .target(
            name: "SessionTestSupport",
            dependencies: ["Session"],
            path: "Sources/TestSupport"
        ),
        .testTarget(
            name: "SessionUnitTests",
            dependencies: ["Session"],
            path: "Tests/SessionUnitTests"
        ),
        .testTarget(
            name: "SessionAcceptanceTests",
            dependencies: ["Session", "SessionDI", "SessionData"],
            path: "Tests/SessionAcceptanceTests"
        )
    ]
)
