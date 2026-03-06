// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CutCopyApp",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "CutCopyApp",
            targets: ["CutCopyApp"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "CutCopyApp"
        ),
        .testTarget(
            name: "CutCopyAppTests",
            dependencies: ["CutCopyApp"]
        ),
    ]
)
