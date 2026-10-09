// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Remendo",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "Remendo",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/Remendo",
            linkerSettings: [
                // Sparkle.framework fica em Remendo.app/Contents/Frameworks.
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
            ]
        )
    ]
)
