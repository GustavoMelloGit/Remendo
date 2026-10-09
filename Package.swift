// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Remendo",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Remendo",
            path: "Sources/Remendo"
        )
    ]
)
