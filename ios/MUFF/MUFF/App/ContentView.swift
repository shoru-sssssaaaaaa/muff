import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeContainerView()
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("検索", systemImage: "magnifyingglass")
            }
            .tag(1)

            NavigationStack {
                BookmarkFoldersView()
            }
            .tabItem {
                Label("ブックマーク", systemImage: "bookmark.fill")
            }
            .tag(2)

            NavigationStack {
                SettingsTopView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
    }
}
