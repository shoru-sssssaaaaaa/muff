import SwiftUI
import WebKit

struct ReaderContentView: View {
    let url: String
    var searchTrigger: Int = 0
    let onFail: () -> Void

    @State private var htmlContent: String?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let html = htmlContent {
                ReaderWebView(html: html, searchTrigger: searchTrigger)
            }
        }
        .task {
            await extractContent()
        }
    }

    private func extractContent() async {
        defer { isLoading = false }

        do {
            guard let requestURL = URL(string: url) else {
                onFail()
                return
            }
            let (data, _) = try await URLSession.shared.data(from: requestURL)
            guard let rawHTML = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .shiftJIS) else {
                onFail()
                return
            }

            let sanitized = rawHTML.sanitizedHTML
            let extracted = extractMainContent(from: sanitized)

            // Strip HTML tags to check actual visible text length
            let visibleText = extracted.replacingOccurrences(
                of: "<[^>]+>",
                with: "",
                options: .regularExpression
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            if visibleText.count < 80 {
                onFail()
                return
            }

            var filtered = applyContentFilters(to: extracted)
            if AppSettings.shared.hideLinkTables {
                filtered = removeLinkHeavyBlocks(from: filtered)
            }
            if AppSettings.shared.hideLinkedImages {
                filtered = removeLinkedImages(from: filtered, pageURL: url)
            }

            // Safety: if filtering removed too much, use unfiltered content
            let filteredText = filtered.replacingOccurrences(
                of: "<[^>]+>", with: "", options: .regularExpression
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            if filteredText.count < 80 {
                filtered = extracted
            }

            let settings = AppSettings.shared
            let styledHTML = """
            <!DOCTYPE html>
            <html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, sans-serif;
                    font-size: \(settings.readerFontSize)px;
                    line-height: \(settings.readerLineSpacing);
                    padding: 16px;
                    color: #333;
                    max-width: 100%;
                    word-wrap: break-word;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #ddd; background: #1c1c1e; }
                    a { color: #58a6ff; }
                }
                img { max-width: 100%; height: auto; }
                pre { overflow-x: auto; }
            </style>
            </head>
            <body>\(filtered)</body>
            </html>
            """

            htmlContent = styledHTML
        } catch {
            onFail()
        }
    }

    private func applyContentFilters(to html: String) -> String {
        let keywords = (try? AppDatabase.shared.contentFilterKeywords()) ?? []
        guard !keywords.isEmpty else { return html }

        var content = html
        // Remove block elements (div, section, aside, ul, ol, table) that contain filter keywords
        let blockTags = ["div", "section", "aside", "ul", "ol", "table", "details"]
        for tag in blockTags {
            for keyword in keywords {
                let flexibleKeyword = Self.flexibleFilterPattern(for: keyword)
                let pattern = "<\(tag)[^>]*>[^<]*(?:<(?!/\(tag))[^<]*)*\(flexibleKeyword)(?:<(?!/\(tag))[^<]*)*</\(tag)>"
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    content = regex.stringByReplacingMatches(
                        in: content,
                        range: NSRange(content.startIndex..., in: content),
                        withTemplate: ""
                    )
                }
            }
        }
        return content
    }

    private static func flexibleFilterPattern(for keyword: String) -> String {
        let parts = keyword.components(separatedBy: CharacterSet(charactersIn: "の　 \t"))
            .filter { !$0.isEmpty }
        guard parts.count > 1 else {
            return NSRegularExpression.escapedPattern(for: keyword)
        }
        return parts.map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "[の\\s]*")
    }

    private func removeLinkedImages(from html: String, pageURL: String) -> String {
        let pageHost = URL(string: pageURL)?.host ?? ""
        var content = html
        let pattern = "<a\\s[^>]*>[\\s\\S]*?</a>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return content }
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: content) else { continue }
            let block = String(content[range])
            // Only target links that contain images
            guard block.range(of: "<img\\s", options: .regularExpression) != nil else { continue }
            // Extract href and check if it's an external domain
            guard let hrefRegex = try? NSRegularExpression(pattern: "href=\"([^\"]*)\"", options: .caseInsensitive),
                  let hrefMatch = hrefRegex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
                  let hrefRange = Range(hrefMatch.range(at: 1), in: block) else { continue }
            let href = String(block[hrefRange])
            // Skip same-domain links
            if let linkHost = URL(string: href)?.host, linkHost == pageHost { continue }
            // Skip links to image files
            let lower = href.lowercased()
            if lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".png")
                || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") || lower.hasSuffix(".svg") { continue }
            // Skip if inside a blockquote
            // (In extracted HTML, blockquote-wrapped content is unlikely to match, but check tag context)
            content.replaceSubrange(range, with: "")
        }
        return content
    }

    private func removeLinkHeavyBlocks(from html: String) -> String {
        var content = html
        let blockTags = ["div", "section", "aside", "ul", "ol", "table", "details", "nav"]
        for tag in blockTags {
            let pattern = "<\(tag)[^>]*>[\\s\\S]*?</\(tag)>"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            // Process in reverse to preserve ranges
            for match in matches.reversed() {
                guard let range = Range(match.range, in: content) else { continue }
                let block = String(content[range])
                // Count link tags
                let linkPattern = "<a\\s[^>]*>"
                let linkCount = (try? NSRegularExpression(pattern: linkPattern, options: .caseInsensitive))?
                    .numberOfMatches(in: block, range: NSRange(block.startIndex..., in: block)) ?? 0
                guard linkCount >= 3 else { continue }
                // Compare link text vs total text
                let stripped = block.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let linkTextPattern = "<a[^>]*>([\\s\\S]*?)</a>"
                var linkTextLength = 0
                if let linkRegex = try? NSRegularExpression(pattern: linkTextPattern, options: .caseInsensitive) {
                    let linkMatches = linkRegex.matches(in: block, range: NSRange(block.startIndex..., in: block))
                    for lm in linkMatches {
                        if let r = Range(lm.range(at: 1), in: block) {
                            let text = String(block[r]).replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            linkTextLength += text.count
                        }
                    }
                }
                if stripped.count > 0 && Double(linkTextLength) / Double(stripped.count) > 0.5 {
                    content.replaceSubrange(range, with: "")
                }
            }
        }
        return content
    }

    private func extractMainContent(from html: String) -> String {
        // Simple content extraction: find the largest text block
        // Remove navigation, header, footer, sidebar elements
        var content = html

        let removePatterns = [
            "<nav[^>]*>[\\s\\S]*?</nav>",
            "<header[^>]*>[\\s\\S]*?</header>",
            "<footer[^>]*>[\\s\\S]*?</footer>",
            "<aside[^>]*>[\\s\\S]*?</aside>",
            "<iframe[^>]*>[\\s\\S]*?</iframe>",
        ]

        for pattern in removePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                content = regex.stringByReplacingMatches(
                    in: content,
                    range: NSRange(content.startIndex..., in: content),
                    withTemplate: ""
                )
            }
        }

        // Try to find article or main content
        let contentPatterns = [
            "<article[^>]*>([\\s\\S]*?)</article>",
            "<main[^>]*>([\\s\\S]*?)</main>",
            "<div[^>]*class=\"[^\"]*(?:entry|content|article|post)[^\"]*\"[^>]*>([\\s\\S]*?)</div>",
        ]

        for pattern in contentPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
               let range = Range(match.range(at: 1), in: content) {
                return String(content[range])
            }
        }

        // Fallback: return body content
        if let bodyRegex = try? NSRegularExpression(pattern: "<body[^>]*>([\\s\\S]*?)</body>", options: .caseInsensitive),
           let match = bodyRegex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range(at: 1), in: content) {
            return String(content[range])
        }

        return content
    }
}

private struct ReaderWebView: UIViewRepresentable {
    let html: String
    var searchTrigger: Int = 0

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isFindInteractionEnabled = true
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if searchTrigger != context.coordinator.lastSearchTrigger {
            context.coordinator.lastSearchTrigger = searchTrigger
            if searchTrigger > 0 {
                webView.findInteraction?.presentFindNavigator(showingReplace: false)
            }
        }
    }

    class Coordinator {
        var lastSearchTrigger = 0
    }
}
