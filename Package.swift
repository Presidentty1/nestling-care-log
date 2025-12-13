// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NestlingTests",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        // Add minimal dependencies needed for testing
    ],
    targets: [
        .testTarget(
            name: "CelebrationThrottleTests",
            dependencies: [],
            path: "tests",
            sources: ["CelebrationThrottleTests.swift"]
        ),
        .testTarget(
            name: "ContextualBadgeLogicTests", 
            dependencies: [],
            path: "tests",
            sources: ["ContextualBadgeLogicTests.swift"]
        ),
        .testTarget(
            name: "PolishFeatureFlagsTests",
            dependencies: [],
            path: "tests", 
            sources: ["PolishFeatureFlagsTests.swift"]
        ),
        .testTarget(
            name: "UndoServiceTests",
            dependencies: [],
            path: "tests",
            sources: ["UndoServiceTests.swift"]
        )
    ]
)