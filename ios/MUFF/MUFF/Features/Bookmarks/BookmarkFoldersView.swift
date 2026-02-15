import SwiftUI

struct BookmarkFoldersView: View {
    @State private var viewModel = BookmarkViewModel()
    @State private var showNewFolder = false
    @State private var renameTarget: BookmarkFolder?
    @State private var showDeleteAlert = false
    @State private var deleteTarget: BookmarkFolder?

    var body: some View {
        List {
            if viewModel.folders.isEmpty {
                ContentUnavailableView {
                    Label("ブックマークなし", systemImage: "bookmark")
                } description: {
                    Text("記事をブックマークすると、ここに表示されます")
                }
            } else {
                ForEach(viewModel.folders) { folder in
                    NavigationLink(value: folder) {
                        HStack {
                            Image(systemName: "folder")
                            Text(folder.name)
                            Spacer()
                        }
                    }
                    .contextMenu {
                        Button("名前を変更") {
                            renameTarget = folder
                        }
                        Button("削除", role: .destructive) {
                            deleteTarget = folder
                            showDeleteAlert = true
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("ブックマーク")
        .navigationDestination(for: BookmarkFolder.self) { folder in
            BookmarkItemsView(folder: folder, viewModel: viewModel)
        }
        .toolbar {
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
                viewModel.createFolder(name: name)
            }
        }
        .alert("フォルダを削除", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                if let target = deleteTarget {
                    viewModel.deleteFolder(id: target.id)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("フォルダ内のブックマークもすべて削除されます")
        }
        .onAppear {
            viewModel.loadFolders()
        }
    }
}
