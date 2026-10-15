// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CursorHalo",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "CursorHaloCore"),
        .executableTarget(name: "CursorHalo", dependencies: ["CursorHaloCore"]),
        .testTarget(name: "CursorHaloCoreTests", dependencies: ["CursorHaloCore"]),
    ]
)
