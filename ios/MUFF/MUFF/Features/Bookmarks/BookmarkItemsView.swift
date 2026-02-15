import SwiftUI

struct BookmarkItemsView: View {
    let folder: BookmarkFolder
    @Bindable var viewModel: BookmarkViewModel
    @State private var selectedArticle: ArticleResponse?

    var body: some View {
        let items = viewModel.items[folder.id] ?? []

        List {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("空のフォルダ", systemImage: "bookmark")
                } description: {
                    Text("このフォルダにはブックマークがありません")
                }
            } else {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.sourceName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(item.title)
                            .font(.subheadline)
                            .lineLimit(2)
                        Text(item.category)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture {
                        selectedArticle = ArticleResponse(
                            articleId: item.articleId,
                            sourceId: "",
                            sourceName: item.sourceName,
                            title: item.title,
                            url: item.url,
                            publishedAt: "",
                            thumbnailUrl: item.thumbnailUrl,
                            category: item.category,
                            viewCount: nil
                        )
                    }
                    .swipeActions(edge: .trailing) {
                        Button("削除", role: .destructive) {
                            viewModel.removeBookmark(id: item.id, folderId: folder.id)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(folder.name)
        .navigationDestination(item: $selectedArticle) { article in
            ArticleDetailView(article: article, articles: [article], currentIndex: 0)
        }
        .onAppear {
            viewModel.loadItems(folderId: folder.id)
        }
    }
}
