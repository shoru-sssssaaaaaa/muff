import Foundation
import GRDB

struct CachedArticle: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "cached_articles"

    var articleId: String
    var sourceId: String
    var sourceName: String
    var title: String
    var url: String
    var publishedAt: String
    var thumbnailUrl: String?
    var category: String
    var viewCount: Int?
    var feedType: String
    var cachedAt: Date

    var id: String { articleId }

    enum Columns {
        static let articleId = Column(CodingKeys.articleId)
        static let sourceId = Column(CodingKeys.sourceId)
        static let sourceName = Column(CodingKeys.sourceName)
        static let title = Column(CodingKeys.title)
        static let url = Column(CodingKeys.url)
        static let publishedAt = Column(CodingKeys.publishedAt)
        static let thumbnailUrl = Column(CodingKeys.thumbnailUrl)
        static let category = Column(CodingKeys.category)
        static let viewCount = Column(CodingKeys.viewCount)
        static let feedType = Column(CodingKeys.feedType)
        static let cachedAt = Column(CodingKeys.cachedAt)
    }

    init(article: ArticleResponse, feedType: String) {
        self.articleId = article.articleId
        self.sourceId = article.sourceId
        self.sourceName = article.sourceName
        self.title = article.title
        self.url = article.url
        self.publishedAt = article.publishedAt
        self.thumbnailUrl = article.thumbnailUrl
        self.category = article.category
        self.viewCount = article.viewCount
        self.feedType = feedType
        self.cachedAt = Date()
    }

    func toArticleResponse() -> ArticleResponse {
        ArticleResponse(
            articleId: articleId,
            sourceId: sourceId,
            sourceName: sourceName,
            title: title,
            url: url,
            publishedAt: publishedAt,
            thumbnailUrl: thumbnailUrl,
            category: category,
            viewCount: viewCount
        )
    }
}
