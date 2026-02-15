import Foundation

// MARK: - Server API Response Models
// These match backend ApiModels.kt exactly (snake_case via keyDecodingStrategy)

struct SourceResponse: Codable, Identifiable, Hashable, Sendable {
    let sourceId: String
    let name: String
    let rssUrl: String
    let siteUrl: String
    let defaultCategory: String
    let status: String

    var id: String { sourceId }
}

struct ArticleResponse: Codable, Identifiable, Hashable, Sendable {
    let articleId: String
    let sourceId: String
    let sourceName: String
    let title: String
    let url: String
    let publishedAt: String
    let thumbnailUrl: String?
    let category: String
    let viewCount: Int?

    var id: String { articleId }

    var publishedDate: Date? {
        ISO8601DateFormatter().date(from: publishedAt)
    }
}

struct FeedResponse: Codable, Sendable {
    let items: [ArticleResponse]
    let nextCursor: String?
}

struct OpenEventRequest: Codable, Sendable {
    let articleUrl: String
    let articleId: String?
    let occurredAt: String
    let anonDeviceIdHash: String
    let appVersion: String
}

struct ErrorResponse: Codable, Sendable {
    let error: String
    let message: String
}

struct StatusResponse: Codable, Sendable {
    let status: String
}
