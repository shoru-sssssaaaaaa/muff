import SwiftUI

struct FolderPickerSheet: View {
    let article: ArticleResponse

    @State private var folders: [BookmarkFolder] = []
    @State private var showNewFolder = false
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if folders.isEmpty {
                    Text("フォルダがありません。新しく作成してください。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(folders) { folder in
                        Button {
                            try? AppDatabase.shared.addBookmark(folderId: folder.id, article: article)
                            saved = true
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                Text(folder.name)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("保存先を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewFolder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewFolder) {
                NewFolderSheet { name in
                    if let folder = try? AppDatabase.shared.createBookmarkFolder(name: name) {
                        folders.append(folder)
                    }
                }
            }
            .onAppear {
                folders = (try? AppDatabase.shared.allBookmarkFolders()) ?? []
            }
        }
        .presentationDetents([.medium])
    }
}
