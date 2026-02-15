import Foundation
import GRDB

struct HistoryEntry: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "history_entries"

    var id: String
    var url: String
    var title: String
    var sourceName: String
    var viewedAt: Date

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let url = Column(CodingKeys.url)
        static let title = Column(CodingKeys.title)
        static let sourceName = Column(CodingKeys.sourceName)
        static let viewedAt = Column(CodingKeys.viewedAt)
    }

    init(article: ArticleResponse) {
        self.id = UUID().uuidString
        self.url = article.url
        self.title = article.title
        self.sourceName = article.sourceName
        self.viewedAt = Date()
    }
}
