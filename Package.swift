// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Storix",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Storix", targets: ["Storix"]),
        .library(name: "StorixCore", targets: ["StorixCore"]),
        .library(name: "StorixCleaner", targets: ["StorixCleaner"]),
        .library(name: "StorixAI", targets: ["StorixAI"]),
        .library(name: "StorixAgent", targets: ["StorixAgent"]),
        .library(name: "StorixUI", targets: ["StorixUI"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Storix",
            dependencies: [
                "StorixCore",
                "StorixCleaner",
                "StorixAI",
                "StorixAgent",
                "StorixUI"
            ],
            path: "App",
            exclude: ["Info.plist", "Storix.entitlements"]
        ),
        .target(
            name: "StorixCore",
            path: "Sources/StorixCore"
        ),
        .target(
            name: "StorixCleaner",
            dependencies: ["StorixCore"],
            path: "Sources/StorixCleaner"
        ),
        .target(
            name: "StorixAI",
            dependencies: ["StorixCore"],
            path: "Sources/StorixAI"
        ),
        .target(
            name: "StorixAgent",
            dependencies: ["StorixCore", "StorixCleaner"],
            path: "Sources/StorixAgent"
        ),
        .target(
            name: "StorixUI",
            dependencies: ["StorixCore", "StorixCleaner", "StorixAI", "StorixAgent"],
            path: "Sources/StorixUI"
        ),
        .testTarget(
            name: "StorixCoreTests",
            dependencies: ["StorixCore"],
            path: "Tests/StorixCoreTests"
        )
    ]
)
