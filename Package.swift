// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GlassDemo",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "GlassDemo")
    ]
)
