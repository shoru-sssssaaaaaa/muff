import Foundation
import GRDB

struct UserSource: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "user_sources"

    var id: String
    var name: String
    var rssUrl: String
    var siteUrl: String
    var category: String
    var isEnabled: Bool
    var lastFetchAt: Date?
    var consecutiveFailures: Int
    var createdAt: Date

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let rssUrl = Column(CodingKeys.rssUrl)
        static let siteUrl = Column(CodingKeys.siteUrl)
        static let category = Column(CodingKeys.category)
        static let isEnabled = Column(CodingKeys.isEnabled)
        static let lastFetchAt = Column(CodingKeys.lastFetchAt)
        static let consecutiveFailures = Column(CodingKeys.consecutiveFailures)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    init(name: String, rssUrl: String, siteUrl: String, category: String) {
        self.id = UUID().uuidString
        self.name = name
        self.rssUrl = rssUrl
        self.siteUrl = siteUrl
        self.category = category
        self.isEnabled = true
        self.lastFetchAt = nil
        self.consecutiveFailures = 0
        self.createdAt = Date()
    }
}
