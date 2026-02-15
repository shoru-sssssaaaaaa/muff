import Foundation

extension String {
    var sanitizedHTML: String {
        // Remove script tags and their content
        var result = self
        let scriptPattern = "<script[^>]*>[\\s\\S]*?</script>"
        if let regex = try? NSRegularExpression(pattern: scriptPattern, options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

        // Remove style tags and their content
        let stylePattern = "<style[^>]*>[\\s\\S]*?</style>"
        if let regex = try? NSRegularExpression(pattern: stylePattern, options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

        // Remove event handlers
        let eventPattern = "\\s+on\\w+=\"[^\"]*\""
        if let regex = try? NSRegularExpression(pattern: eventPattern, options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

        return result
    }
}
