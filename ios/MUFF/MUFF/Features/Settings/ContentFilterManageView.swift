import SwiftUI

struct ContentFilterManageView: View {
    @State private var filters: [ContentFilter] = []
    @State private var showAdd = false
    @State private var newKeyword = ""

    private static let defaultSuggestions = [
        "おすすめ記事",
        "関連記事",
        "人気記事",
        "注目記事",
        "こちらもおすすめ",
        "ランキング",
        "よく読まれている記事",
        "話題の記事",
    ]

    private var availableSuggestions: [String] {
        let existing = Set(filters.map { $0.keyword })
        return Self.defaultSuggestions.filter { !existing.contains($0) }
    }

    var body: some View {
        List {
            ForEach(filters) { filter in
                Text(filter.keyword)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    try? AppDatabase.shared.deleteContentFilter(id: filters[index].id)
                }
                filters.remove(atOffsets: indexSet)
            }

            ForEach(availableSuggestions, id: \.self) { (suggestion: String) in
                Button {
                    try? AppDatabase.shared.addContentFilter(suggestion)
                    loadFilters()
                } label: {
                    HStack {
                        Text(suggestion)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
        .navigationTitle("記事内フィルター")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("フィルター追加", isPresented: $showAdd) {
            TextField("キーワードを入力", text: $newKeyword)
            Button("追加") {
                let trimmed = newKeyword.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    try? AppDatabase.shared.addContentFilter(trimmed)
                    newKeyword = ""
                    loadFilters()
                }
            }
            Button("キャンセル", role: .cancel) {
                newKeyword = ""
            }
        }
        .onAppear { loadFilters() }
    }

    private func loadFilters() {
        filters = (try? AppDatabase.shared.allContentFilters()) ?? []
    }
}
