import SwiftUI

struct PopularFeedView: View {
    var refreshTrigger: Int = 0
    @State private var viewModel = PopularFeedViewModel()
    @State private var selectedArticle: ArticleResponse?
    @State private var selectedIndex: Int = 0

    var body: some View {
        Group {
            if viewModel.articles.isEmpty && viewModel.isLoading {
                LoadingView()
            } else if viewModel.articles.isEmpty, let error = viewModel.error {
                ErrorView(error) {
                    Task { await viewModel.load() }
                }
            } else {
                ArticleListView(
                    articles: viewModel.articles,
                    isLoading: viewModel.isLoading,
                    hasMore: false,
                    onLoadMore: {},
                    onArticleTap: { article, index in
                        selectedIndex = index
                        selectedArticle = article
                    },
                    onRefresh: { await viewModel.refresh() },
                    scrollToTopTrigger: refreshTrigger
                )
            }
        }
        .navigationDestination(item: $selectedArticle) { article in
            ArticleDetailView(
                article: article,
                articles: viewModel.articles,
                currentIndex: selectedIndex
            )
        }
        .task {
            if viewModel.articles.isEmpty {
                await viewModel.load()
            }
        }
        .onChange(of: refreshTrigger) {
            Task { await viewModel.refresh() }
        }
    }
}
