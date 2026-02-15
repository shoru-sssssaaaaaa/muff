import Foundation
import GRDB

struct ContentFilter: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "content_filters"

    var id: String
    var keyword: String
    var createdAt: Date

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let keyword = Column(CodingKeys.keyword)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    init(keyword: String) {
        self.id = UUID().uuidString
        self.keyword = keyword
        self.createdAt = Date()
    }
}
