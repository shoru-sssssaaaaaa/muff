import SwiftUI

struct SettingsTopView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        List {
            Section("表示") {
                Toggle("ダークモード", isOn: Binding(
                    get: { settings.darkModeEnabled },
                    set: { settings.darkModeEnabled = $0 }
                ))

                Toggle("サムネイル表示", isOn: Binding(
                    get: { settings.showThumbnails },
                    set: { settings.showThumbnails = $0 }
                ))

                Picker("既読記事の表示", selection: Binding(
                    get: { settings.readArticleDisplayMode },
                    set: { settings.readArticleDisplayMode = $0 }
                )) {
                    ForEach(ReadArticleDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }

            Section("記事閲覧設定") {
                NavigationLink("Readerモード設定") {
                    ReaderSettingsView()
                }

                NavigationLink("フォロー管理") {
                    FollowManageView()
                }

                NavigationLink("ミュート管理") {
                    MuteManageView()
                }

                NavigationLink("NGワード") {
                    NGWordManageView()
                }

                NavigationLink("記事内フィルター") {
                    ContentFilterManageView()
                }

                Toggle("リンク一覧を非表示", isOn: Binding(
                    get: { settings.hideLinkTables },
                    set: { settings.hideLinkTables = $0 }
                ))

                Toggle("リンク付き画像を非表示", isOn: Binding(
                    get: { settings.hideLinkedImages },
                    set: { settings.hideLinkedImages = $0 }
                ))

                Toggle("広告ブロック", isOn: Binding(
                    get: { settings.adBlockEnabled },
                    set: { settings.adBlockEnabled = $0 }
                ))
            }

            Section("ソース") {
                NavigationLink("ソース一覧") {
                    SourcesListView()
                }
            }

            Section("通知") {
                NavigationLink("通知設定") {
                    NotificationSettingsView()
                }
            }

            Section("情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("設定")
    }
}
