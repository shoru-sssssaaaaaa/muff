import Foundation
import GRDB

enum FollowType: String, Codable, Sendable {
    case category
    case site
    case keyword
}

struct FollowRule: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "follow_rules"

    var id: String
    var type: FollowType
    var value: String
    var createdAt: Date

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let type = Column(CodingKeys.type)
        static let value = Column(CodingKeys.value)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    init(type: FollowType, value: String) {
        self.id = UUID().uuidString
        self.type = type
        self.value = value
        self.createdAt = Date()
    }
}
