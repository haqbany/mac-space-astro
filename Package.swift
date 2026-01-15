// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacSpaceAstro",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacSpaceAstro", targets: ["AstroApp"]),
        .library(name: "CoreSystemKit", targets: ["CoreSystemKit"]),
        .library(name: "CleanupEngine", targets: ["CleanupEngine"]),
        .library(name: "AstroAI", targets: ["AstroAI"]),
        .library(name: "AstroUI", targets: ["AstroUI"]),
        .library(name: "ImageEngine", targets: ["ImageEngine"])
    ],
    dependencies: [
        // Potential dependencies for AI:
        // .package(url: "https://github.com/ggerganov/llama.cpp", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "AstroApp",
            dependencies: ["CoreSystemKit", "CleanupEngine", "AstroAI", "AstroUI", "ImageEngine"],
            path: "Sources/AstroApp"
        ),
        .target(
            name: "CoreSystemKit",
            dependencies: [],
            path: "Sources/CoreSystemKit"
        ),
        .target(
            name: "CleanupEngine",
            dependencies: ["CoreSystemKit"],
            path: "Sources/CleanupEngine"
        ),
        .target(
            name: "ImageEngine",
            dependencies: [],
            path: "Sources/ImageEngine"
        ),
        .target(
            name: "AstroAI",
            dependencies: [],
            path: "Sources/AstroAI"
        ),
        .target(
            name: "AstroUI",
            dependencies: ["CoreSystemKit", "CleanupEngine", "AstroAI", "ImageEngine"],
            path: "Sources/UI"
        )
    ]
)
