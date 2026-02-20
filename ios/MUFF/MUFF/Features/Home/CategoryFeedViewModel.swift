import Foundation

@MainActor
@Observable
final class CategoryFeedViewModel {
    let category: String
    private(set) var articles: [ArticleResponse] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var nextCursor: String?
    private(set) var hasMore = true

    private let apiClient: APIClient

    init(category: String, apiClient: APIClient = APIClient()) {
        self.category = category
        self.apiClient = apiClient
    }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        nextCursor = nil

        do {
            let response = try await apiClient.fetchCategoryFeed(category: category)
            articles = response.items
            nextCursor = response.nextCursor
            hasMore = response.nextCursor != nil
            try? AppDatabase.shared.cacheArticles(response.items, feedType: "category:\(category)")
        } catch {
            if let cached = try? AppDatabase.shared.cachedArticles(feedType: "category:\(category)"), !cached.isEmpty {
                articles = cached
            }
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, hasMore, let cursor = nextCursor else { return }
        isLoading = true

        do {
            let response = try await apiClient.fetchCategoryFeed(category: category, cursor: cursor)
            articles.append(contentsOf: response.items)
            nextCursor = response.nextCursor
            hasMore = response.nextCursor != nil
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
