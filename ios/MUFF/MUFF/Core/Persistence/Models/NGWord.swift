import Foundation
import GRDB

struct NGWord: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "ng_words"

    var id: String
    var word: String
    var createdAt: Date

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let word = Column(CodingKeys.word)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    init(word: String) {
        self.id = UUID().uuidString
        self.word = word
        self.createdAt = Date()
    }
}
