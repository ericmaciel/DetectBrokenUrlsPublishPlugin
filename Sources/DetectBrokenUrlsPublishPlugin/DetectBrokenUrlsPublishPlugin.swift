//
//  DetectBrokenUrlsPublishPlugin.swift
//
//
//  Created by Eric Maciel on 22/09/23.
//

import Files
import Foundation
import Publish
import SwiftSoup

extension Plugin {
    
    /// Detect broken URLs in a specific HTML file relative to the output folder.
    public static func detectBrokenUrls(at path: Path) -> Self {
        Plugin(name: "Detect Broken Urls in file") { context in
            let file = try context.outputFile(at: path)
            try await BrokenUrlsDetector(context: context).scan(file)
        }
    }
    
    /// Detect broken URLs in all HTML files in a folder relative to the output folder.
    public static func detectBrokenUrls(in path: Path = "", includingSubfolders: Bool = true) -> Self {
        Plugin(name: "Detect Broken Urls in folder") { context in
            let folder = try context.outputFolder(at: path)
            let files = includingSubfolders ? folder.files.recursive : folder.files
            try await files.concurrentForEach(BrokenUrlsDetector(context: context).scan)
        }
    }
}

struct BrokenUrlsDetector<Site: Website> {
    let outputFolder: Folder
    
    init(context: PublishingContext<Site>) throws {
        outputFolder = try context.outputFolder(at: "")
    }
    
    func scan(_ file: File) async throws {
        guard file.extension == "html" else {
            return
        }
        
        let html = try file.readAsString()
        try await scan(html: html, path: Path(file.path))
    }
    
    func scan(html: String, path: Path) async throws {

        let document = try SwiftSoup.parse(html)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            
            // Check link elements
            let linkElements = try document.select("a")
            for element in linkElements {
                group.addTask {
                    let linkHref = try element.attr("href")
                    let linkText = try element.text().orEmpty("a href")
                    
                    if linkHref.first == "#" {
                        let elementId = String(linkHref.dropFirst())
                        if try document.getElementById(elementId) == nil {
                            throw PublishingError(infoMessage: "Can't find element with id '\(elementId) (\(linkText))' in file at '\(path)'")
                        }
                    } else {
                        try await checkAvailability(target: linkHref, text: linkText, path: path)
                    }
                }
            }
            
            // Check image elements
            let imgElements = try document.select("img")
            for element in imgElements {
                group.addTask {
                    let imgSrc = try element.attr("src")
                    let imgText = try element.attr("title")
                        .orEmpty(try element.attr("alt"))
                        .orEmpty("img src")
                    try await checkAvailability(target: imgSrc, text: imgText, path: path)
                }
            }
            
            // Check source elements
            let sourceElements = try document.select("source")
            for element in sourceElements {
                group.addTask {
                    let imgSrc = try element.attr("srcset")
                    try await checkAvailability(target: imgSrc, text: "source srcset", path: path)
                }
            }
            
            // Check form elements
            let formElements = try document.select("form")
            for element in formElements {
                group.addTask {
                    let formAction = try element.attr("action")
                    try await checkAvailability(target: formAction, text: "form action", path: path)
                }
            }
            
            // Check iframe elements
            let iframeElements = try document.select("iframe")
            for element in iframeElements {
                group.addTask {
                    let iframeSrc = try element.attr("src")
                    let iframeTitle = try element.attr("title").orEmpty("iframe src")
                    try await checkAvailability(target: iframeSrc, text: iframeTitle, path: path)
                }
            }
            
            // Propagate any errors thrown by the group's tasks
            for try await _ in group {}
        }
    }
    
    func checkAvailability(target: String, text: String, path: Path) async throws {
        guard let url = URL(string: target) else {
            return
        }

        guard let scheme = url.scheme, !scheme.isEmpty else {
            // Not remote, check for local resource
            // Using url.path to avoid url fragment (like in "/path/filename.html#fragment")
            let targetPath = if url.path.first != "/", let folderPath = try? File(path: path.string).parent?.path {
                Path(folderPath).appendingComponent(url.path).string
            } else {
                url.path
            }
            let notFound = !(outputFolder.containsFile(at: targetPath)
                             || outputFolder.containsSubfolder(at: targetPath))
            if notFound {
                throw PublishingError(infoMessage: "Can't find the path to '\(targetPath)' (reference is '\(text)' in file at '\(path)'")
            }
            return
        }
        
        guard scheme.hasPrefix("http") else {
            // Other schemes are ignored
            return
        }
        var statusCode = 200
        do {
            // Check for remote resource
            let response = try await getResponse(for: url)
            let failStatusCodes = [404, 410]
            guard failStatusCodes.contains(response.statusCode) else {
                return
            }
            statusCode = response.statusCode
        } catch {
            throw PublishingError(infoMessage: "Can't reach the url at '\(url)' (link text is '\(text)') in file at '\(path)'")
        }
        throw PublishingError(infoMessage: "Can't find the url at '\(url)' (link text is '\(text)') (status code: \(statusCode)) in file at '\(path)'")
    }
    
    func getResponse(for url: URL) async throws -> HTTPURLResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 15
        let (_, response) = try await URLSession.shared.data(for: request)
        return response as! HTTPURLResponse
    }
}

extension String {
    func orEmpty(_ alt: @autoclosure () throws -> String) rethrows -> String {
        self.isEmpty ? try alt() : self
    }
}
