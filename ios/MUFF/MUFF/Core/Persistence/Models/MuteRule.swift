import Foundation
import GRDB

enum MuteType: String, Codable, Sendable {
    case category
    case site
}

enum MuteDuration: String, CaseIterable, Sendable {
    case hours24 = "24時間"
    case permanent = "無期限"
}

struct MuteRule: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "mute_rules"

    var id: String
    var type: MuteType
    var value: String
    var disabledUntil: Date?
    var createdAt: Date
    var expiresAt: Date?

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let type = Column(CodingKeys.type)
        static let value = Column(CodingKeys.value)
        static let disabledUntil = Column(CodingKeys.disabledUntil)
        static let createdAt = Column(CodingKeys.createdAt)
        static let expiresAt = Column(CodingKeys.expiresAt)
    }

    init(type: MuteType, value: String, expiresAt: Date? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.value = value
        self.disabledUntil = nil
        self.createdAt = Date()
        self.expiresAt = expiresAt
    }

    /// Active when not temporarily disabled AND not expired
    var isActive: Bool {
        if let disabledUntil, Date() < disabledUntil {
            return false
        }
        if let expiresAt, Date() >= expiresAt {
            return false
        }
        return true
    }

    var isPermanent: Bool {
        expiresAt == nil
    }
}
