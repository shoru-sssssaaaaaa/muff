import SwiftUI

struct SourcesListView: View {
    @State private var officialSources: [SourceResponse] = []
    @State private var userSources: [UserSource] = []
    @State private var isLoading = false
    @State private var showConfirm = false
    @State private var confirmSourceId: String?
    @State private var confirmSourceName: String?

    var body: some View {
        List {
            Section("デフォルトソース") {
                if isLoading {
                    ProgressView()
                } else {
                    ForEach(officialSources) { source in
                        sourceRow(source)
                    }
                }
            }

            Section("ユーザー追加RSS") {
                ForEach(userSources) { source in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(source.name)
                                    .font(.body)
                                if source.consecutiveFailures > 0 {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.caption)
                                }
                            }
                            Text(source.rssUrl)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { source.isEnabled },
                            set: { try? AppDatabase.shared.toggleUserSource(id: source.id, enabled: $0); loadUserSources() }
                        ))
                        .labelsHidden()
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        try? AppDatabase.shared.deleteUserSource(id: userSources[index].id)
                    }
                    loadUserSources()
                }

                NavigationLink("RSS追加") {
                    AddRSSView {
                        loadUserSources()
                    }
                }
            }
        }
        .navigationTitle("ソース")
        .task { await loadOfficialSources() }
        .onAppear { loadUserSources() }
        .alert("無効化しますか？", isPresented: $showConfirm) {
            Button("はい") {
                if let id = confirmSourceId {
                    AppSettings.shared.disabledDefaultSourceIds.insert(id)
                }
            }
            Button("いいえ", role: .cancel) {}
        } message: {
            Text("\(confirmSourceName ?? "") を無効にすると、このソースの記事がフィードに表示されなくなります。")
        }
    }

    @ViewBuilder
    private func sourceRow(_ source: SourceResponse) -> some View {
        let isDisabled = AppSettings.shared.disabledDefaultSourceIds.contains(source.sourceId)
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(source.name)
                    .font(.body)
                Text(source.siteUrl)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                if isDisabled {
                    AppSettings.shared.disabledDefaultSourceIds.remove(source.sourceId)
                } else {
                    confirmSourceId = source.sourceId
                    confirmSourceName = source.name
                    showConfirm = true
                }
            } label: {
                Text(isDisabled ? "inactive" : "active")
                    .font(.caption)
                    .foregroundStyle(isDisabled ? Color.secondary : Color.green)
            }
            .buttonStyle(.plain)
        }
    }

    private func loadOfficialSources() async {
        isLoading = true
        officialSources = (try? await APIClient().fetchSources()) ?? []
        isLoading = false
    }

    private func loadUserSources() {
        userSources = (try? AppDatabase.shared.allUserSources()) ?? []
    }
}
