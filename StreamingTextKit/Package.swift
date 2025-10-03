// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StreamingTextKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "StreamingTextKit",
            targets: ["StreamingTextKit"]
        )
    ],
    targets: [
        .target(
            name: "StreamingTextKit",
            dependencies: []
        ),
        .testTarget(
            name: "StreamingTextKitTests",
            dependencies: ["StreamingTextKit"]
        ),
    ]
)
