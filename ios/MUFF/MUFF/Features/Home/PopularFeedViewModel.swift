import Foundation

@MainActor
@Observable
final class PopularFeedViewModel {
    private(set) var articles: [ArticleResponse] = []
    private(set) var isLoading = false
    private(set) var error: String?

    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let response = try await apiClient.fetchPopularFeed()
            if response.items.isEmpty {
                // No popularity data — fall back to new feed (chronological)
                let fallback = try await apiClient.fetchNewFeed()
                articles = fallback.items.sorted { $0.publishedAt > $1.publishedAt }
                try? AppDatabase.shared.cacheArticles(fallback.items, feedType: "popular")
            } else {
                articles = response.items.sorted { ($0.viewCount ?? 0) > ($1.viewCount ?? 0) }
                try? AppDatabase.shared.cacheArticles(response.items, feedType: "popular")
            }
        } catch {
            if let cached = try? AppDatabase.shared.cachedArticles(feedType: "popular"), !cached.isEmpty {
                articles = cached.sorted { ($0.viewCount ?? 0) > ($1.viewCount ?? 0) }
            }
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        articles = []
        await load()
    }
}
