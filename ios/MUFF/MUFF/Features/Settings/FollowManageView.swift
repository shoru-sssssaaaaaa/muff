import SwiftUI

struct FollowManageView: View {
    @State private var rules: [FollowRule] = []
    @State private var showAddSheet = false

    var body: some View {
        List {
            if rules.isEmpty {
                ContentUnavailableView {
                    Label("フォローなし", systemImage: "heart")
                } description: {
                    Text("カテゴリ、サイト、キーワードをフォローすると、フォローフィードに表示されます")
                }
            } else {
                ForEach(rules) { rule in
                    HStack {
                        Label {
                            Text(rule.value)
                        } icon: {
                            Image(systemName: iconForType(rule.type))
                        }

                        Spacer()

                        Text(labelForType(rule.type))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        try? AppDatabase.shared.deleteFollowRule(id: rules[index].id)
                    }
                    rules.remove(atOffsets: indexSet)
                }
            }
        }
        .navigationTitle("フォロー管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            KeywordAddSheet(initialKeyword: "") { type, value in
                try? AppDatabase.shared.addFollowRule(type: type, value: value)
                loadRules()
            }
        }
        .onAppear { loadRules() }
    }

    private func loadRules() {
        rules = (try? AppDatabase.shared.allFollowRules()) ?? []
    }

    private func iconForType(_ type: FollowType) -> String {
        switch type {
        case .category: return "folder"
        case .site: return "globe"
        case .keyword: return "magnifyingglass"
        }
    }

    private func labelForType(_ type: FollowType) -> String {
        switch type {
        case .category: return "カテゴリ"
        case .site: return "サイト"
        case .keyword: return "キーワード"
        }
    }
}
