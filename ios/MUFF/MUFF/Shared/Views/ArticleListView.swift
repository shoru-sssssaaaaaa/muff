import SwiftUI
import GRDB

struct ArticleListView: View {
    let articles: [ArticleResponse]
    let isLoading: Bool
    let hasMore: Bool
    let onLoadMore: () -> Void
    let onArticleTap: (ArticleResponse, Int) -> Void
    let onRefresh: () async -> Void
    var scrollToTopTrigger: Int = 0

    @State private var readURLs: Set<String> = []
    @State private var muteRules: [MuteRule] = []
    @State private var ngWords: [NGWord] = []

    var body: some View {
        ScrollViewReader { proxy in
        List {
            Color.clear
                .frame(height: 0)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .id("articleListTop")

            ForEach(Array(filteredArticles.enumerated()), id: \.element.id) { index, article in
                let isRead = readURLs.contains(article.url)
                let ngMatch = matchingNGWord(for: article)

                ArticleCardView(
                    article: article,
                    isRead: isRead,
                    ngWarning: ngMatch
                )
                .onTapGesture {
                    onArticleTap(article, index)
                }
                .onAppear {
                    if index == filteredArticles.count - 3 && hasMore && !isLoading {
                        onLoadMore()
                    }
                }
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGray5))
        .refreshable {
            await onRefresh()
        }
        .onAppear {
            muteRules = (try? AppDatabase.shared.activeMuteRules()) ?? []
            ngWords = (try? AppDatabase.shared.allNGWords()) ?? []
        }
        .task {
            // Reactively observe read_articles table via GRDB ValueObservation.
            // Yields the current set immediately, then again whenever the table changes.
            let observation = ValueObservation.tracking { db in
                try String.fetchAll(db, sql: "SELECT url FROM read_articles")
            }
            do {
                for try await urls in observation.values(in: AppDatabase.shared.dbQueue) {
                    readURLs = Set(urls)
                }
            } catch {
                readURLs = (try? AppDatabase.shared.allReadURLs()) ?? []
            }
        }
        .onChange(of: scrollToTopTrigger) {
            withAnimation {
                proxy.scrollTo("articleListTop", anchor: .top)
            }
        }
        } // ScrollViewReader
    }

    private var filteredArticles: [ArticleResponse] {
        let settings = AppSettings.shared
        return articles.filter { article in
            // Apply mute rules
            for rule in muteRules where rule.isActive {
                switch rule.type {
                case .category:
                    if article.category == rule.value { return false }
                case .site:
                    if article.sourceId == rule.value || article.sourceName == rule.value { return false }
                }
            }

            // Apply disabled default sources
            if settings.disabledDefaultSourceIds.contains(article.sourceId) {
                return false
            }

            // Apply read article display mode
            if readURLs.contains(article.url) && settings.readArticleDisplayMode == .hide {
                return false
            }

            return true
        }
    }

    private func matchingNGWord(for article: ArticleResponse) -> String? {
        for ngWord in ngWords {
            if article.title.localizedCaseInsensitiveContains(ngWord.word) {
                return ngWord.word
            }
        }
        return nil
    }
}
