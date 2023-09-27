// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "DetectBrokenUrlsPublishPlugin",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "DetectBrokenUrlsPublishPlugin",
            targets: ["DetectBrokenUrlsPublishPlugin"]
        ),
        .executable(
            name: "DetectBrokenUrlsPublishPluginDemo",
            targets: ["DetectBrokenUrlsPublishPluginDemo"]
        )
    ],
    dependencies: [
        .package(name: "Publish", url: "https://github.com/johnsundell/publish.git", from: "0.8.0"),
        .package(name: "SwiftSoup", url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "DetectBrokenUrlsPublishPlugin",
            dependencies: ["Publish", "SwiftSoup"]
        ),
        .executableTarget(
            name: "DetectBrokenUrlsPublishPluginDemo",
            dependencies: ["Publish", "DetectBrokenUrlsPublishPlugin"]
        )
    ]
)
