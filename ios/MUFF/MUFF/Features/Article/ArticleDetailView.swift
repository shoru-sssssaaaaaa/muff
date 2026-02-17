import SwiftUI

struct ArticleDetailView: View {
    @State private var viewModel: ArticleDetailViewModel
    @State private var showBookmarkPicker = false
    @State private var showSettings = false
    @State private var isWebFiltering: Bool
    @State private var searchTrigger = 0
    @State private var webViewId = 0

    private static var needsFiltering: Bool {
        let hasKeywords = !((try? AppDatabase.shared.contentFilterKeywords()) ?? []).isEmpty
        return hasKeywords || AppSettings.shared.hideLinkTables || AppSettings.shared.hideLinkedImages
    }

    init(article: ArticleResponse, articles: [ArticleResponse], currentIndex: Int) {
        self._viewModel = State(initialValue: ArticleDetailViewModel(
            article: article,
            articles: articles,
            currentIndex: currentIndex
        ))
        self._isWebFiltering = State(initialValue: Self.needsFiltering)
    }

    var body: some View {
        ZStack {
            if viewModel.isReaderMode && !viewModel.readerFailed {
                ReaderContentView(
                    url: viewModel.currentArticle.url,
                    searchTrigger: searchTrigger,
                    onFail: {
                        viewModel.readerFailed = true
                    }
                )
                .id(webViewId)
            } else {
                WebContentView(
                    url: viewModel.currentArticle.url,
                    searchTrigger: searchTrigger,
                    onFiltered: {
                        isWebFiltering = false
                    }
                )
                .id(webViewId)

                if isWebFiltering {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("表示設定を適用中...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 && viewModel.canGoNext {
                        viewModel.goNext()
                    } else if value.translation.width > 50 && viewModel.canGoPrevious {
                        viewModel.goPrevious()
                    }
                }
        )
        .navigationTitle(viewModel.currentArticle.sourceName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    searchTrigger += 1
                } label: {
                    Label("検索", systemImage: "magnifyingglass")
                }

                Spacer()

                Button {
                    showBookmarkPicker = true
                } label: {
                    Label("ブックマーク", systemImage: viewModel.isBookmarked() ? "star.fill" : "star")
                }

                Spacer()

                Button {
                    showSettings = true
                } label: {
                    Label("設定", systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showBookmarkPicker) {
            FolderPickerSheet(article: viewModel.currentArticle)
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            webViewId += 1
            isWebFiltering = Self.needsFiltering
        }) {
            NavigationStack {
                SettingsTopView()
            }
        }
        .onChange(of: viewModel.currentArticle.url) {
            isWebFiltering = Self.needsFiltering
        }
        .onAppear {
            viewModel.markAsRead()
            Task { await viewModel.sendOpenEvent() }
        }
    }
}
