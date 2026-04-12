// swift-tools-version: 5.9

import Foundation
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
        .library(
            name: "AgentWallieMCPCore",
            targets: ["AgentWallieMCPCore"]
        ),
        .executable(
            name: "AgentWallieMCPServer",
            targets: ["AgentWallieMCPServer"]
        ),
        .executable(
            name: "AgentWallieLibraryTestHarness",
            targets: ["AgentWallieLibraryTestHarness"]
        ),
    ],
    targets: [
        .target(
            name: "AgentWallieKit",
            path: "Sources/AgentWallieKit"
        ),
        .target(
            name: "AgentWallieMCPCore",
            dependencies: ["AgentWallieKit"],
            path: "Sources/AgentWallieMCPCore"
        ),
        .executableTarget(
            name: "AgentWallieMCPServer",
            dependencies: ["AgentWallieMCPCore"],
            path: "Sources/AgentWallieMCPServer"
        ),
        .executableTarget(
            name: "AgentWallieMCPTestHarness",
            dependencies: ["AgentWallieMCPCore"],
            path: "Sources/AgentWallieMCPTestHarness"
        ),
        .executableTarget(
            name: "AgentWallieLibraryTestHarness",
            dependencies: ["AgentWallieKit"],
            path: "Sources/AgentWallieLibraryTestHarness"
        ),
    ]
)
