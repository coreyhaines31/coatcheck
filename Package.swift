// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoatCheck",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CoatCheck", targets: ["CoatCheck"]), .executable(name: "CoatCheckCLI", targets: ["CoatCheckCLI"])],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
        // Brushed popover components. Pinned to the PanelKit branch until it merges to main.
        .package(url: "https://github.com/coreyhaines31/mac-app-kit", branch: "feature/2-panelkit")
    ],
    targets: [
        .target(name: "CoatCheckCore"),
        .executableTarget(name: "CoatCheck", dependencies: [
            "CoatCheckCore",
            .product(name: "Sparkle", package: "Sparkle"),
            .product(name: "PanelKit", package: "mac-app-kit")
        ]),
        .executableTarget(name: "CoatCheckCLI", dependencies: ["CoatCheckCore"]),
        .testTarget(name: "CoatCheckCoreTests", dependencies: ["CoatCheckCore"])
    ]
)
