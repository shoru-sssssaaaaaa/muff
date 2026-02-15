import XCTest
import GRDB
@testable import MUFF

final class AppDatabaseTests: XCTestCase {
    var db: AppDatabase!

    override func setUpWithError() throws {
        let dbQueue = try DatabaseQueue()
        db = try AppDatabase(dbQueue)
    }

    // MARK: - Read Articles

    func testMarkAsRead() throws {
        let url = "https://example.com/article/1"
        XCTAssertFalse(try db.isRead(url: url))
        try db.markAsRead(url: url)
        XCTAssertTrue(try db.isRead(url: url))
    }

    func testAllReadURLs() throws {
        try db.markAsRead(url: "https://example.com/1")
        try db.markAsRead(url: "https://example.com/2")
        let urls = try db.allReadURLs()
        XCTAssertEqual(urls.count, 2)
        XCTAssertTrue(urls.contains("https://example.com/1"))
        XCTAssertTrue(urls.contains("https://example.com/2"))
    }

    // MARK: - Bookmark Folders

    func testCreateAndListFolders() throws {
        let folder = try db.createBookmarkFolder(name: "Test Folder")
        XCTAssertEqual(folder.name, "Test Folder")

        let folders = try db.allBookmarkFolders()
        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folders[0].name, "Test Folder")
    }

    func testDeleteFolder() throws {
        let folder = try db.createBookmarkFolder(name: "To Delete")
        try db.deleteBookmarkFolder(id: folder.id)
        let folders = try db.allBookmarkFolders()
        XCTAssertTrue(folders.isEmpty)
    }

    func testRenameFolder() throws {
        let folder = try db.createBookmarkFolder(name: "Old Name")
        try db.renameBookmarkFolder(id: folder.id, name: "New Name")
        let folders = try db.allBookmarkFolders()
        XCTAssertEqual(folders[0].name, "New Name")
    }

    // MARK: - Bookmark Items

    func testAddAndListBookmarks() throws {
        let folder = try db.createBookmarkFolder(name: "Folder")
        let article = ArticleResponse(
            articleId: "a1", sourceId: "s1", sourceName: "Source",
            title: "Title", url: "https://example.com/1",
            publishedAt: "2026-02-13T10:00:00Z", category: "news"
        )
        try db.addBookmark(folderId: folder.id, article: article)
        let items = try db.bookmarkItems(inFolder: folder.id)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].title, "Title")
    }

    func testIsBookmarked() throws {
        let folder = try db.createBookmarkFolder(name: "Folder")
        let article = ArticleResponse(
            articleId: "a1", sourceId: "s1", sourceName: "Source",
            title: "Title", url: "https://example.com/1",
            publishedAt: "2026-02-13T10:00:00Z", category: "news"
        )
        XCTAssertFalse(try db.isBookmarked(url: article.url))
        try db.addBookmark(folderId: folder.id, article: article)
        XCTAssertTrue(try db.isBookmarked(url: article.url))
    }

    // MARK: - Follow Rules

    func testFollowRules() throws {
        try db.addFollowRule(type: .keyword, value: "Swift")
        try db.addFollowRule(type: .category, value: "IT")
        let rules = try db.allFollowRules()
        XCTAssertEqual(rules.count, 2)
    }

    func testDeleteFollowRule() throws {
        try db.addFollowRule(type: .keyword, value: "Test")
        var rules = try db.allFollowRules()
        XCTAssertEqual(rules.count, 1)
        try db.deleteFollowRule(id: rules[0].id)
        rules = try db.allFollowRules()
        XCTAssertTrue(rules.isEmpty)
    }

    // MARK: - Mute Rules

    func testMuteRules() throws {
        try db.addMuteRule(type: .category, value: "芸能")
        let rules = try db.allMuteRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertTrue(rules[0].isActive)
    }

    func testTemporarilyDisableMute() throws {
        try db.addMuteRule(type: .site, value: "example.com")
        var rules = try db.allMuteRules()
        try db.temporarilyDisableMute(id: rules[0].id)
        rules = try db.allMuteRules()
        XCTAssertFalse(rules[0].isActive)
        XCTAssertNotNil(rules[0].disabledUntil)
    }

    // MARK: - NG Words

    func testNGWords() throws {
        try db.addNGWord("テスト")
        let words = try db.allNGWords()
        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(words[0].word, "テスト")
    }

    // MARK: - Cached Articles

    func testCacheAndSearch() throws {
        let articles = [
            ArticleResponse(
                articleId: "a1", sourceId: "s1", sourceName: "Source",
                title: "SwiftUI入門", url: "https://example.com/1",
                publishedAt: "2026-02-13T10:00:00Z", category: "IT"
            ),
            ArticleResponse(
                articleId: "a2", sourceId: "s1", sourceName: "Source",
                title: "Kotlin入門", url: "https://example.com/2",
                publishedAt: "2026-02-13T11:00:00Z", category: "IT"
            ),
        ]
        try db.cacheArticles(articles, feedType: "new")

        let cached = try db.cachedArticles(feedType: "new")
        XCTAssertEqual(cached.count, 2)

        let searchResults = try db.searchCachedArticles(query: "Swift")
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults[0].title, "SwiftUI入門")
    }
}
