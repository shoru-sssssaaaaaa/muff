import Foundation

@MainActor
@Observable
final class FollowFeedViewModel {
    private(set) var articles: [ArticleResponse] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var followRules: [FollowRule] = []

    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            followRules = (try? AppDatabase.shared.allFollowRules()) ?? []

            if followRules.isEmpty {
                articles = []
                isLoading = false
                return
            }

            // Fetch new feed and filter by follow rules
            let response = try await apiClient.fetchNewFeed(limit: 50)
            articles = response.items.filter { article in
                matchesFollowRules(article)
            }.sorted { $0.publishedAt > $1.publishedAt }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        isLoading = false
        await load()
    }

    private func matchesFollowRules(_ article: ArticleResponse) -> Bool {
        for rule in followRules {
            switch rule.type {
            case .category:
                if article.category == rule.value { return true }
            case .site:
                if article.sourceId == rule.value || article.sourceName == rule.value { return true }
            case .keyword:
                if article.title.localizedCaseInsensitiveContains(rule.value) { return true }
            }
        }
        return false
    }
}
