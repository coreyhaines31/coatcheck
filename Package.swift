// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoatCheck",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CoatCheck", targets: ["CoatCheck"])],
    targets: [
        .target(name: "CoatCheckCore"),
        .executableTarget(name: "CoatCheck", dependencies: ["CoatCheckCore"]),
        .testTarget(name: "CoatCheckCoreTests", dependencies: ["CoatCheckCore"])
    ]
)
