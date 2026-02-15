import Foundation

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    private(set) var results: [ArticleResponse] = []
    private(set) var isSearching = false

    func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }

        isSearching = true
        results = (try? AppDatabase.shared.searchCachedArticles(query: query)) ?? []
        isSearching = false
    }
}
