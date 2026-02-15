import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var selectedArticle: ArticleResponse?
    @State private var selectedIndex: Int = 0
    @State private var showKeywordAdd = false

    var body: some View {
        List {
            if viewModel.results.isEmpty && !viewModel.query.isEmpty && !viewModel.isSearching {
                ContentUnavailableView.search(text: viewModel.query)
            } else {
                ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { index, article in
                    ArticleCardView(article: article, isRead: false, ngWarning: nil)
                        .onTapGesture {
                            selectedIndex = index
                            selectedArticle = article
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGray5))
        .searchable(text: $viewModel.query, prompt: "記事タイトルを検索")
        .onSubmit(of: .search) {
            viewModel.search()
        }
        .onChange(of: viewModel.query) { _, newValue in
            if newValue.isEmpty {
                viewModel.search()
            }
        }
        .navigationTitle("検索")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.query.isEmpty {
                    Button {
                        showKeywordAdd = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
        .navigationDestination(item: $selectedArticle) { article in
            ArticleDetailView(
                article: article,
                articles: viewModel.results,
                currentIndex: selectedIndex
            )
        }
        .sheet(isPresented: $showKeywordAdd) {
            KeywordAddSheet(initialKeyword: viewModel.query)
        }
    }
}
