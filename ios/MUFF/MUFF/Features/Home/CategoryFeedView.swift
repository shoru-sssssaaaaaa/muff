import SwiftUI

struct CategoryFeedView: View {
    let category: String
    @State private var viewModel: CategoryFeedViewModel
    @State private var selectedArticle: ArticleResponse?
    @State private var selectedIndex: Int = 0

    init(category: String) {
        self.category = category
        self._viewModel = State(initialValue: CategoryFeedViewModel(category: category))
    }

    var body: some View {
        Group {
            if viewModel.articles.isEmpty && viewModel.isLoading {
                LoadingView()
            } else if viewModel.articles.isEmpty, let error = viewModel.error {
                ErrorView(error) {
                    Task { await viewModel.loadInitial() }
                }
            } else {
                ArticleListView(
                    articles: viewModel.articles,
                    isLoading: viewModel.isLoading,
                    hasMore: viewModel.hasMore,
                    onLoadMore: { Task { await viewModel.loadMore() } },
                    onArticleTap: { article, index in
                        selectedIndex = index
                        selectedArticle = article
                    },
                    onRefresh: { await viewModel.refresh() }
                )
            }
        }
        .navigationTitle(category)
        .navigationDestination(item: $selectedArticle) { article in
            ArticleDetailView(
                article: article,
                articles: viewModel.articles,
                currentIndex: selectedIndex
            )
        }
        .task {
            if viewModel.articles.isEmpty {
                await viewModel.loadInitial()
            }
        }
    }
}
