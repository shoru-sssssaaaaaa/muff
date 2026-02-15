import Foundation
import GRDB

struct BookmarkItem: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "bookmark_items"

    var id: String
    var folderId: String
    var articleId: String
    var title: String
    var url: String
    var sourceName: String
    var thumbnailUrl: String?
    var category: String
    var bookmarkedAt: Date

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let folderId = Column(CodingKeys.folderId)
        static let articleId = Column(CodingKeys.articleId)
        static let title = Column(CodingKeys.title)
        static let url = Column(CodingKeys.url)
        static let sourceName = Column(CodingKeys.sourceName)
        static let thumbnailUrl = Column(CodingKeys.thumbnailUrl)
        static let category = Column(CodingKeys.category)
        static let bookmarkedAt = Column(CodingKeys.bookmarkedAt)
    }

    init(folderId: String, article: ArticleResponse) {
        self.id = UUID().uuidString
        self.folderId = folderId
        self.articleId = article.articleId
        self.title = article.title
        self.url = article.url
        self.sourceName = article.sourceName
        self.thumbnailUrl = article.thumbnailUrl
        self.category = article.category
        self.bookmarkedAt = Date()
    }
}
