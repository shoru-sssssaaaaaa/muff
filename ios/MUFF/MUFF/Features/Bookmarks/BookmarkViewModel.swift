import Foundation

@MainActor
@Observable
final class BookmarkViewModel {
    private(set) var folders: [BookmarkFolder] = []
    private(set) var items: [String: [BookmarkItem]] = [:]

    func loadFolders() {
        folders = (try? AppDatabase.shared.allBookmarkFolders()) ?? []
    }

    func loadItems(folderId: String) {
        items[folderId] = (try? AppDatabase.shared.bookmarkItems(inFolder: folderId)) ?? []
    }

    func createFolder(name: String) {
        if let folder = try? AppDatabase.shared.createBookmarkFolder(name: name) {
            folders.append(folder)
        }
    }

    func deleteFolder(id: String) {
        try? AppDatabase.shared.deleteBookmarkFolder(id: id)
        folders.removeAll { $0.id == id }
        items.removeValue(forKey: id)
    }

    func renameFolder(id: String, name: String) {
        try? AppDatabase.shared.renameBookmarkFolder(id: id, name: name)
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].name = name
        }
    }

    func removeBookmark(id: String, folderId: String) {
        try? AppDatabase.shared.removeBookmark(id: id)
        items[folderId]?.removeAll { $0.id == id }
    }
}
