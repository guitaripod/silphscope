// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MarkdownKit", targets: ["MarkdownKit"])
    ],
    targets: [
        .target(name: "MarkdownKit"),
        .testTarget(name: "MarkdownKitTests", dependencies: ["MarkdownKit"])
    ]
)
