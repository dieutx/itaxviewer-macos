// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iTaxViewerMac",
    defaultLocalization: "vi",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "iTaxViewerMac", targets: ["iTaxViewerMac"]),
        .executable(name: "iTaxViewerQA", targets: ["iTaxViewerQA"]),
        .library(name: "iTaxViewerCore", targets: ["iTaxViewerCore"])
    ],
    targets: [
        .target(
            name: "iTaxViewerCore",
            path: "Sources/iTaxViewerCore",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "iTaxViewerMac",
            dependencies: ["iTaxViewerCore"],
            path: "Sources/iTaxViewerMac"
        ),
        .executableTarget(
            name: "iTaxViewerQA",
            dependencies: ["iTaxViewerCore"],
            path: "Sources/iTaxViewerQA"
        ),
        .testTarget(
            name: "iTaxViewerCoreTests",
            dependencies: ["iTaxViewerCore"],
            path: "Tests/iTaxViewerCoreTests",
            resources: [.copy("Fixtures")]
        )
    ]
)
