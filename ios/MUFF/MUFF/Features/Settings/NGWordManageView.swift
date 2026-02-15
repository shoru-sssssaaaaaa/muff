import SwiftUI

struct NGWordManageView: View {
    @State private var words: [NGWord] = []
    @State private var showAdd = false
    @State private var newWord = ""

    var body: some View {
        List {
            if words.isEmpty {
                ContentUnavailableView {
                    Label("NGワードなし", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("NGワードを追加すると、タイトルに含まれる記事に注意ラベルが表示されます")
                }
            } else {
                ForEach(words) { word in
                    Text(word.word)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        try? AppDatabase.shared.deleteNGWord(id: words[index].id)
                    }
                    words.remove(atOffsets: indexSet)
                }
            }
        }
        .navigationTitle("NGワード")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("NGワード追加", isPresented: $showAdd) {
            TextField("ワードを入力", text: $newWord)
            Button("追加") {
                let trimmed = newWord.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    try? AppDatabase.shared.addNGWord(trimmed)
                    newWord = ""
                    loadWords()
                }
            }
            Button("キャンセル", role: .cancel) {
                newWord = ""
            }
        }
        .onAppear { loadWords() }
    }

    private func loadWords() {
        words = (try? AppDatabase.shared.allNGWords()) ?? []
    }
}
