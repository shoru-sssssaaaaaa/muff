import SwiftUI

struct FollowFeedView: View {
    var refreshTrigger: Int = 0
    @State private var viewModel = FollowFeedViewModel()
    @State private var selectedArticle: ArticleResponse?
    @State private var selectedIndex: Int = 0

    var body: some View {
        Group {
            if viewModel.followRules.isEmpty && !viewModel.isLoading {
                ContentUnavailableView {
                    Label("フォローなし", systemImage: "heart")
                } description: {
                    Text("カテゴリ、サイト、キーワードをフォローすると、ここに表示されます")
                } actions: {
                    NavigationLink("フォロー管理") {
                        FollowManageView()
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.articles.isEmpty && viewModel.isLoading {
                LoadingView()
            } else if viewModel.articles.isEmpty, let error = viewModel.error {
                ErrorView(error) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.articles.isEmpty {
                ContentUnavailableView {
                    Label("記事なし", systemImage: "doc.text")
                } description: {
                    Text("フォロー条件に一致する記事がありません")
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
            await viewModel.load()
        }
        .onChange(of: refreshTrigger) {
            Task { await viewModel.refresh() }
        }
    }
}
