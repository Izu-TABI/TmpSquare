// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "DropShelf",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DropShelf",
            path: "Sources/DropShelf"
        ),
        .testTarget(
            name: "DropShelfTests",
            dependencies: ["DropShelf"],
            path: "Tests/DropShelfTests"
        ),
    ]
)
