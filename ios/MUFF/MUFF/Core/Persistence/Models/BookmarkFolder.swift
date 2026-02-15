import Foundation
import GRDB

struct BookmarkFolder: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable, Sendable {
    static let databaseTableName = "bookmark_folders"

    var id: String
    var name: String
    var createdAt: Date
    var sortOrder: Int

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let createdAt = Column(CodingKeys.createdAt)
        static let sortOrder = Column(CodingKeys.sortOrder)
    }

    init(id: String = UUID().uuidString, name: String, createdAt: Date = Date(), sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}
