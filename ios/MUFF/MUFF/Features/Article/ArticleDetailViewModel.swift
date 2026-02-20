import Foundation

@MainActor
@Observable
final class ArticleDetailViewModel {
    var currentArticle: ArticleResponse
    var articles: [ArticleResponse]
    var currentIndex: Int
    var isReaderMode: Bool
    var readerHTML: String?
    var readerFailed = false
    var bookmarked = false

    private let apiClient = APIClient()

    init(article: ArticleResponse, articles: [ArticleResponse], currentIndex: Int) {
        self.currentArticle = article
        self.articles = articles
        self.currentIndex = currentIndex
        self.isReaderMode = AppSettings.shared.readerModeEnabled
        self.bookmarked = (try? AppDatabase.shared.isBookmarked(url: article.url)) ?? false
    }

    func markAsRead() {
        try? AppDatabase.shared.markAsRead(url: currentArticle.url)
        try? AppDatabase.shared.addHistory(article: currentArticle)
    }

    func sendOpenEvent() async {
        let event = OpenEventRequest(
            articleUrl: currentArticle.url,
            articleId: currentArticle.articleId,
            occurredAt: ISO8601DateFormatter().string(from: Date()),
            anonDeviceIdHash: AnonymousIDManager.shared.deviceIdHash,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        )
        try? await apiClient.postOpenEvent(event)
    }

    var canGoNext: Bool {
        currentIndex < articles.count - 1
    }

    var canGoPrevious: Bool {
        currentIndex > 0
    }

    func goNext() {
        guard canGoNext else { return }
        currentIndex += 1
        currentArticle = articles[currentIndex]
        readerHTML = nil
        readerFailed = false
        refreshBookmarkState()
        markAsRead()
        Task { await sendOpenEvent() }
    }

    func goPrevious() {
        guard canGoPrevious else { return }
        currentIndex -= 1
        currentArticle = articles[currentIndex]
        readerHTML = nil
        readerFailed = false
        refreshBookmarkState()
        markAsRead()
        Task { await sendOpenEvent() }
    }

    func refreshBookmarkState() {
        bookmarked = (try? AppDatabase.shared.isBookmarked(url: currentArticle.url)) ?? false
    }
}
