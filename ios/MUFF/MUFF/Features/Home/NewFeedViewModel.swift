import Foundation

@MainActor
@Observable
final class NewFeedViewModel {
    private(set) var articles: [ArticleResponse] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var nextCursor: String?
    private(set) var hasMore = true

    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        nextCursor = nil

        do {
            let response = try await apiClient.fetchNewFeed()
            articles = response.items.sorted { $0.publishedAt > $1.publishedAt }
            nextCursor = response.nextCursor
            hasMore = response.nextCursor != nil
            // Cache articles
            try? AppDatabase.shared.cacheArticles(response.items, feedType: "new")
        } catch {
            // Try cache on failure
            if let cached = try? AppDatabase.shared.cachedArticles(feedType: "new"), !cached.isEmpty {
                articles = cached.sorted { $0.publishedAt > $1.publishedAt }
            }
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, hasMore, let cursor = nextCursor else { return }
        isLoading = true

        do {
            let response = try await apiClient.fetchNewFeed(cursor: cursor)
            articles.append(contentsOf: response.items)
            nextCursor = response.nextCursor
            hasMore = response.nextCursor != nil
            try? AppDatabase.shared.cacheArticles(response.items, feedType: "new")
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        hasMore = true
        nextCursor = nil
        isLoading = false
        await loadInitial()
    }
}
