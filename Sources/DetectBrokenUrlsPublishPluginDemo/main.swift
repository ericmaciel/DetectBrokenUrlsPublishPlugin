import DetectBrokenUrlsPublishPlugin
import Foundation
import Publish
import Plot

// This type acts as the configuration for your website.
struct DetectBrokenUrlsPublishPluginDemo: Website {
    enum SectionID: String, WebsiteSectionID {
        // Add the sections that you want your website to contain here:
        case posts
    }

    struct ItemMetadata: WebsiteItemMetadata {
        // Add any site-specific metadata that you want to use here.
    }

    // Update these properties to configure your website:
    var url = URL(string: "https://your-website-url.com")!
    var name = "DetectBrokenLinksPublishPlugin"
    var description = "A description of DetectBrokenUrlsPublishPluginDemo"
    var language: Language { .english }
    var imagePath: Path? { nil }
}

// This will generate your website using the built-in Foundation theme:
try DetectBrokenUrlsPublishPluginDemo().publish(using: [.optional(.copyResources()),
                                                        .addMarkdownFiles(),
                                                        .sortItems(by: \.date, order: .descending),
                                                        .generateHTML(withTheme: .foundation),
                                                        .generateRSSFeed(
                                                            including: Set(DetectBrokenUrlsPublishPluginDemo.SectionID.allCases),
                                                            config: .default
                                                        ),
                                                        .installPlugin(.detectBrokenUrls())])
