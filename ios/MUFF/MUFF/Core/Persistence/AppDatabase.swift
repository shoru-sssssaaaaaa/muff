import Foundation
import GRDB

final class AppDatabase: Sendable {
    let dbQueue: DatabaseQueue

    init(_ dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1") { db in
            // read_articles
            try db.create(table: "read_articles") { t in
                t.primaryKey("url", .text)
                t.column("readAt", .datetime).notNull()
            }

            // bookmark_folders
            try db.create(table: "bookmark_folders") { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("sortOrder", .integer).notNull().defaults(to: 0)
            }

            // bookmark_items
            try db.create(table: "bookmark_items") { t in
                t.primaryKey("id", .text)
                t.column("folderId", .text).notNull()
                    .references("bookmark_folders", onDelete: .cascade)
                t.column("articleId", .text).notNull()
                t.column("title", .text).notNull()
                t.column("url", .text).notNull()
                t.column("sourceName", .text).notNull()
                t.column("thumbnailUrl", .text)
                t.column("category", .text).notNull()
                t.column("bookmarkedAt", .datetime).notNull()
            }

            // history_entries
            try db.create(table: "history_entries") { t in
                t.primaryKey("id", .text)
                t.column("url", .text).notNull()
                t.column("title", .text).notNull()
                t.column("sourceName", .text).notNull()
                t.column("viewedAt", .datetime).notNull()
            }

            // follow_rules
            try db.create(table: "follow_rules") { t in
                t.primaryKey("id", .text)
                t.column("type", .text).notNull()
                t.column("value", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }

            // mute_rules
            try db.create(table: "mute_rules") { t in
                t.primaryKey("id", .text)
                t.column("type", .text).notNull()
                t.column("value", .text).notNull()
                t.column("disabledUntil", .datetime)
                t.column("createdAt", .datetime).notNull()
            }

            // ng_words
            try db.create(table: "ng_words") { t in
                t.primaryKey("id", .text)
                t.column("word", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }

            // user_sources
            try db.create(table: "user_sources") { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("rssUrl", .text).notNull().unique()
                t.column("siteUrl", .text).notNull()
                t.column("category", .text).notNull()
                t.column("isEnabled", .boolean).notNull().defaults(to: true)
                t.column("lastFetchAt", .datetime)
                t.column("consecutiveFailures", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
            }

            // cached_articles
            try db.create(table: "cached_articles") { t in
                t.primaryKey("articleId", .text)
                t.column("sourceId", .text).notNull()
                t.column("sourceName", .text).notNull()
                t.column("title", .text).notNull()
                t.column("url", .text).notNull().unique()
                t.column("publishedAt", .text).notNull()
                t.column("thumbnailUrl", .text)
                t.column("category", .text).notNull()
                t.column("viewCount", .integer)
                t.column("feedType", .text).notNull()
                t.column("cachedAt", .datetime).notNull()
            }
        }

        migrator.registerMigration("v2") { db in
            try db.alter(table: "mute_rules") { t in
                t.add(column: "expiresAt", .datetime)
            }
        }

        migrator.registerMigration("v3") { db in
            try db.create(table: "content_filters") { t in
                t.primaryKey("id", .text)
                t.column("keyword", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }
        }

        migrator.registerMigration("v4") { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM content_filters") ?? 0
            if count == 0 {
                let keywords = [
                    "おすすめ記事", "関連記事", "人気記事", "注目記事",
                    "こちらもおすすめ", "ランキング", "よく読まれている記事", "話題の記事",
                ]
                let now = Date()
                for keyword in keywords {
                    try db.execute(
                        sql: "INSERT INTO content_filters (id, keyword, createdAt) VALUES (?, ?, ?)",
                        arguments: [UUID().uuidString, keyword, now]
                    )
                }
            }
        }

        return migrator
    }

    // MARK: - Default Database

    static let shared = makeShared()

    private static func makeShared() -> AppDatabase {
        do {
            let url = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("muff.sqlite")
            let dbQueue = try DatabaseQueue(path: url.path)
            return try AppDatabase(dbQueue)
        } catch {
            fatalError("Database initialization failed: \(error)")
        }
    }

    // MARK: - Read Articles

    func isRead(url: String) throws -> Bool {
        try dbQueue.read { db in
            try ReadArticle.fetchOne(db, key: url) != nil
        }
    }

    func markAsRead(url: String) throws {
        try dbQueue.write { db in
            try ReadArticle(url: url, readAt: Date()).save(db)
        }
    }

    func allReadURLs() throws -> Set<String> {
        try dbQueue.read { db in
            let urls = try String.fetchAll(db, sql: "SELECT url FROM read_articles")
            return Set(urls)
        }
    }

    // MARK: - Bookmark Folders

    func allBookmarkFolders() throws -> [BookmarkFolder] {
        try dbQueue.read { db in
            try BookmarkFolder.order(BookmarkFolder.Columns.sortOrder.asc).fetchAll(db)
        }
    }

    func createBookmarkFolder(name: String) throws -> BookmarkFolder {
        try dbQueue.write { db in
            let maxOrder = try Int.fetchOne(db, sql: "SELECT MAX(sortOrder) FROM bookmark_folders") ?? 0
            let folder = BookmarkFolder(name: name, sortOrder: maxOrder + 1)
            try folder.save(db)
            return folder
        }
    }

    func deleteBookmarkFolder(id: String) throws {
        try dbQueue.write { db in
            _ = try BookmarkFolder.deleteOne(db, key: id)
        }
    }

    func renameBookmarkFolder(id: String, name: String) throws {
        try dbQueue.write { db in
            if var folder = try BookmarkFolder.fetchOne(db, key: id) {
                folder.name = name
                try folder.update(db)
            }
        }
    }

    // MARK: - Bookmark Items

    func bookmarkItems(inFolder folderId: String) throws -> [BookmarkItem] {
        try dbQueue.read { db in
            try BookmarkItem
                .filter(BookmarkItem.Columns.folderId == folderId)
                .order(BookmarkItem.Columns.bookmarkedAt.desc)
                .fetchAll(db)
        }
    }

    func addBookmark(folderId: String, article: ArticleResponse) throws {
        try dbQueue.write { db in
            try BookmarkItem(folderId: folderId, article: article).save(db)
        }
    }

    func removeBookmark(id: String) throws {
        try dbQueue.write { db in
            _ = try BookmarkItem.deleteOne(db, key: id)
        }
    }

    func isBookmarked(url: String) throws -> Bool {
        try dbQueue.read { db in
            try BookmarkItem.filter(BookmarkItem.Columns.url == url).fetchCount(db) > 0
        }
    }

    // MARK: - History

    func addHistory(article: ArticleResponse) throws {
        try dbQueue.write { db in
            try HistoryEntry(article: article).save(db)
        }
    }

    func allHistory() throws -> [HistoryEntry] {
        try dbQueue.read { db in
            try HistoryEntry.order(HistoryEntry.Columns.viewedAt.desc).fetchAll(db)
        }
    }

    func purgeOldHistory() throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        try dbQueue.write { db in
            _ = try HistoryEntry.filter(HistoryEntry.Columns.viewedAt < cutoff).deleteAll(db)
        }
    }

    // MARK: - Follow Rules

    func allFollowRules() throws -> [FollowRule] {
        try dbQueue.read { db in
            try FollowRule.order(FollowRule.Columns.createdAt.desc).fetchAll(db)
        }
    }

    func addFollowRule(type: FollowType, value: String) throws {
        try dbQueue.write { db in
            try FollowRule(type: type, value: value).save(db)
        }
    }

    func deleteFollowRule(id: String) throws {
        try dbQueue.write { db in
            _ = try FollowRule.deleteOne(db, key: id)
        }
    }

    // MARK: - Mute Rules

    func allMuteRules() throws -> [MuteRule] {
        try dbQueue.read { db in
            try MuteRule.order(MuteRule.Columns.createdAt.desc).fetchAll(db)
        }
    }

    func activeMuteRules() throws -> [MuteRule] {
        try allMuteRules().filter { $0.isActive }
    }

    func addMuteRule(type: MuteType, value: String, expiresAt: Date? = nil) throws {
        try dbQueue.write { db in
            try MuteRule(type: type, value: value, expiresAt: expiresAt).save(db)
        }
    }

    func deleteMuteRule(id: String) throws {
        try dbQueue.write { db in
            _ = try MuteRule.deleteOne(db, key: id)
        }
    }

    func temporarilyDisableMute(id: String) throws {
        try dbQueue.write { db in
            if var rule = try MuteRule.fetchOne(db, key: id) {
                rule.disabledUntil = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
                try rule.update(db)
            }
        }
    }

    // MARK: - NG Words

    func allNGWords() throws -> [NGWord] {
        try dbQueue.read { db in
            try NGWord.order(NGWord.Columns.createdAt.desc).fetchAll(db)
        }
    }

    func addNGWord(_ word: String) throws {
        try dbQueue.write { db in
            try NGWord(word: word).save(db)
        }
    }

    func deleteNGWord(id: String) throws {
        try dbQueue.write { db in
            _ = try NGWord.deleteOne(db, key: id)
        }
    }

    // MARK: - Content Filters

    func allContentFilters() throws -> [ContentFilter] {
        try dbQueue.read { db in
            try ContentFilter.order(ContentFilter.Columns.createdAt.desc).fetchAll(db)
        }
    }

    func addContentFilter(_ keyword: String) throws {
        try dbQueue.write { db in
            try ContentFilter(keyword: keyword).save(db)
        }
    }

    func deleteContentFilter(id: String) throws {
        try dbQueue.write { db in
            _ = try ContentFilter.deleteOne(db, key: id)
        }
    }

    func contentFilterKeywords() throws -> [String] {
        try dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT keyword FROM content_filters")
        }
    }

    // MARK: - Distinct Values (for pickers)

    func distinctCategories() throws -> [String] {
        try dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT DISTINCT category FROM cached_articles ORDER BY category")
        }
    }

    func distinctSourceNames() throws -> [String] {
        try dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT DISTINCT sourceName FROM cached_articles ORDER BY sourceName")
        }
    }

    // MARK: - User Sources

    func allUserSources() throws -> [UserSource] {
        try dbQueue.read { db in
            try UserSource.order(UserSource.Columns.createdAt.desc).fetchAll(db)
        }
    }

    func enabledUserSources() throws -> [UserSource] {
        try dbQueue.read { db in
            try UserSource
                .filter(UserSource.Columns.isEnabled == true)
                .fetchAll(db)
        }
    }

    func addUserSource(_ source: UserSource) throws {
        try dbQueue.write { db in
            try source.save(db)
        }
    }

    func deleteUserSource(id: String) throws {
        try dbQueue.write { db in
            _ = try UserSource.deleteOne(db, key: id)
        }
    }

    func toggleUserSource(id: String, enabled: Bool) throws {
        try dbQueue.write { db in
            if var source = try UserSource.fetchOne(db, key: id) {
                source.isEnabled = enabled
                try source.update(db)
            }
        }
    }

    func updateUserSourceFetchStatus(id: String, success: Bool) throws {
        try dbQueue.write { db in
            if var source = try UserSource.fetchOne(db, key: id) {
                source.lastFetchAt = Date()
                if success {
                    source.consecutiveFailures = 0
                } else {
                    source.consecutiveFailures += 1
                }
                try source.update(db)
            }
        }
    }

    // MARK: - Cached Articles

    func cacheArticles(_ articles: [ArticleResponse], feedType: String) throws {
        try dbQueue.write { db in
            for article in articles {
                try CachedArticle(article: article, feedType: feedType).save(db)
            }
        }
    }

    func cachedArticles(feedType: String) throws -> [ArticleResponse] {
        try dbQueue.read { db in
            try CachedArticle
                .filter(CachedArticle.Columns.feedType == feedType)
                .order(CachedArticle.Columns.cachedAt.desc)
                .fetchAll(db)
                .map { $0.toArticleResponse() }
        }
    }

    func searchCachedArticles(query: String) throws -> [ArticleResponse] {
        try dbQueue.read { db in
            try CachedArticle
                .filter(CachedArticle.Columns.title.like("%\(query)%"))
                .order(CachedArticle.Columns.cachedAt.desc)
                .fetchAll(db)
                .map { $0.toArticleResponse() }
        }
    }

    func purgeOldCache() throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        try dbQueue.write { db in
            _ = try CachedArticle.filter(CachedArticle.Columns.cachedAt < cutoff).deleteAll(db)
        }
    }
}
