// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "TmpSquare",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "TmpSquare",
            path: "Sources/TmpSquare"
        ),
        .testTarget(
            name: "TmpSquareTests",
            dependencies: ["TmpSquare"],
            path: "Tests/TmpSquareTests"
        ),
    ]
)
