import XCTest
@testable import MUFF

final class APIClientTests: XCTestCase {
    func testAPIEndpointPaths() {
        XCTAssertEqual(APIEndpoint.catalogSources.path, "/v1/catalog/sources")
        XCTAssertEqual(APIEndpoint.feedNew(cursor: nil, limit: nil).path, "/v1/feed/new")
        XCTAssertEqual(APIEndpoint.feedPopular(limit: nil).path, "/v1/feed/popular")
        XCTAssertEqual(APIEndpoint.feedCategory(category: "news", cursor: nil, limit: nil).path, "/v1/feed/category/news")
        XCTAssertEqual(APIEndpoint.eventsOpen.path, "/v1/events/open")
    }

    func testAPIEndpointMethods() {
        XCTAssertEqual(APIEndpoint.catalogSources.method, "GET")
        XCTAssertEqual(APIEndpoint.feedNew(cursor: nil, limit: nil).method, "GET")
        XCTAssertEqual(APIEndpoint.eventsOpen.method, "POST")
    }

    func testQueryItemsForFeedNew() {
        let endpoint = APIEndpoint.feedNew(cursor: "abc123", limit: 10)
        let items = endpoint.queryItems
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].name, "cursor")
        XCTAssertEqual(items[0].value, "abc123")
        XCTAssertEqual(items[1].name, "limit")
        XCTAssertEqual(items[1].value, "10")
    }

    func testQueryItemsWithNilValues() {
        let endpoint = APIEndpoint.feedNew(cursor: nil, limit: nil)
        XCTAssertTrue(endpoint.queryItems.isEmpty)
    }

    func testArticleResponseDecoding() throws {
        let json = """
        {
            "article_id": "123",
            "source_id": "456",
            "source_name": "Test Source",
            "title": "Test Title",
            "url": "https://example.com/article",
            "published_at": "2026-02-13T10:00:00Z",
            "thumbnail_url": null,
            "category": "news",
            "view_count": 42
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let article = try decoder.decode(ArticleResponse.self, from: json)

        XCTAssertEqual(article.articleId, "123")
        XCTAssertEqual(article.sourceId, "456")
        XCTAssertEqual(article.sourceName, "Test Source")
        XCTAssertEqual(article.title, "Test Title")
        XCTAssertEqual(article.url, "https://example.com/article")
        XCTAssertEqual(article.publishedAt, "2026-02-13T10:00:00Z")
        XCTAssertNil(article.thumbnailUrl)
        XCTAssertEqual(article.category, "news")
        XCTAssertEqual(article.viewCount, 42)
    }

    func testFeedResponseDecoding() throws {
        let json = """
        {
            "items": [
                {
                    "article_id": "1",
                    "source_id": "s1",
                    "source_name": "Source",
                    "title": "Title",
                    "url": "https://example.com/1",
                    "published_at": "2026-02-13T10:00:00Z",
                    "category": "news"
                }
            ],
            "next_cursor": "cursor123"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(FeedResponse.self, from: json)

        XCTAssertEqual(response.items.count, 1)
        XCTAssertEqual(response.nextCursor, "cursor123")
    }

    func testOpenEventRequestEncoding() throws {
        let event = OpenEventRequest(
            articleUrl: "https://example.com/article",
            articleId: "123",
            occurredAt: "2026-02-13T10:00:00Z",
            anonDeviceIdHash: "hash123",
            appVersion: "1.0.0"
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(event)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["article_url"] as? String, "https://example.com/article")
        XCTAssertEqual(dict["article_id"] as? String, "123")
        XCTAssertEqual(dict["occurred_at"] as? String, "2026-02-13T10:00:00Z")
        XCTAssertEqual(dict["anon_device_id_hash"] as? String, "hash123")
        XCTAssertEqual(dict["app_version"] as? String, "1.0.0")
    }
}
