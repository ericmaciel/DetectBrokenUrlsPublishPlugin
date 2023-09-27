# Detect Broken URLs plugin for Publish

A [Publish](https://github.com/johnsundell/publish) plugin to detect broken urls in html files in the output folder.

## Installation

To install it into your [Publish](https://github.com/johnsundell/publish) package, add it as a dependency within your `Package.swift` manifest:

```swift
let package = Package(
    ...
    dependencies: [
        ...
        .package(name: "DetectBrokenUrlsPublishPlugin", url: "https://github.com/[user_name]/detectbrokenurlspublishplugin", from: "0.1.0")
    ],
    targets: [
        .target(
            ...
            dependencies: [
                ...
                "DetectBrokenUrlsPublishPlugin"
            ]
        )
    ]
    ...
)
```

Then import DetectBrokenUrlsPublishPlugin wherever you’d like to use it:

```swift
import DetectBrokenUrlsPublishPlugin
```

For more information on how to use the Swift Package Manager, check out [this article](https://www.swiftbysundell.com/articles/managing-dependencies-using-the-swift-package-manager), or [its official documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).

## Usage

The plugin can then be used within any publishing pipeline like this:

```swift
import DetectBrokenUrlsPublishPlugin
...
try Website().publish(using: [
    ...
    .installPlugin(.detectBrokenUrls),
    ...
])
```

Note, that the html files must already be present in the output folder at the corresponding step in the publishing pipeline. It is therefore best to add this step after `.generateHTML(...)`.

## License

Lincensed under the [MIT license](LICENSE).
