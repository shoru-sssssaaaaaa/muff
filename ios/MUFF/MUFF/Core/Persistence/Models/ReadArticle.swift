import Foundation
import GRDB

struct ReadArticle: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "read_articles"

    var url: String
    var readAt: Date

    enum Columns {
        static let url = Column(CodingKeys.url)
        static let readAt = Column(CodingKeys.readAt)
    }
}
