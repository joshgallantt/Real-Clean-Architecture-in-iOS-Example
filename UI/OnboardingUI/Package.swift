// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OnboardingUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "OnboardingUI",
            targets: ["OnboardingUI"]
        ),
        .library(
            name: "OnboardingUIDI",
            targets: ["OnboardingUIDI"]
        )
    ],
    targets: [
        .target(
            name: "OnboardingUI",
            dependencies: [],
            path: "Sources",
            exclude: ["DI"],
            sources: ["UI"]
        ),
        .target(
            name: "OnboardingUIDI",
            dependencies: ["OnboardingUI"],
            path: "Sources/DI"
        )
    ]
)
