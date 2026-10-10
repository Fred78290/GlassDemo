// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GlassDemo",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "GlassedSheet", targets: ["GlassedSheet"])
    ],
    targets: [
        .target(name: "GlassedSheet"),
        .executableTarget(
            name: "GlassDemo",
            dependencies: ["GlassedSheet"]
        ),
    ]
)
