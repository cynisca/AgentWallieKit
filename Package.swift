// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AgentWallieKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "AgentWallieKit",
            targets: ["AgentWallieKit"]
        ),
    ],
    targets: [
        .target(
            name: "AgentWallieKit",
            path: "Sources/AgentWallieKit"
        ),
        .testTarget(
            name: "AgentWallieKitTests",
            dependencies: ["AgentWallieKit"],
            path: "Tests/AgentWallieKitTests"
        ),
    ]
)
