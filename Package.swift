// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoatCheck",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CoatCheck", targets: ["CoatCheck"]), .executable(name: "CoatCheckCLI", targets: ["CoatCheckCLI"])],
    dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")],
    targets: [
        .target(name: "CoatCheckCore"),
        .executableTarget(name: "CoatCheck", dependencies: ["CoatCheckCore", .product(name: "Sparkle", package: "Sparkle")]),
        .executableTarget(name: "CoatCheckCLI", dependencies: ["CoatCheckCore"]),
        .testTarget(name: "CoatCheckCoreTests", dependencies: ["CoatCheckCore"])
    ]
)
