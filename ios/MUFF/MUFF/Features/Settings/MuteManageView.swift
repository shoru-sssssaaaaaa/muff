import SwiftUI

struct MuteManageView: View {
    @State private var rules: [MuteRule] = []
    @State private var showAddSheet = false

    var body: some View {
        List {
            if rules.isEmpty {
                ContentUnavailableView {
                    Label("ミュートなし", systemImage: "speaker.slash")
                } description: {
                    Text("カテゴリやサイトをミュートすると、フィードから非表示になります")
                }
            } else {
                ForEach(rules) { rule in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rule.value)
                                .font(.body)

                            HStack(spacing: 6) {
                                Text(rule.type == .category ? "カテゴリ" : "サイト")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("·")
                                    .foregroundStyle(.secondary)

                                if rule.isPermanent {
                                    Text("無期限")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if let expiresAt = rule.expiresAt {
                                    if Date() >= expiresAt {
                                        Text("期限切れ")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    } else {
                                        Text("残り \(expiresAt.relativeString)")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }

                        Spacer()

                        if !rule.isActive {
                            if let expiresAt = rule.expiresAt, Date() >= expiresAt {
                                Text("期限切れ")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            } else {
                                Text("一時解除中")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        } else if rule.isPermanent {
                            Button("24h解除") {
                                try? AppDatabase.shared.temporarilyDisableMute(id: rule.id)
                                loadRules()
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        try? AppDatabase.shared.deleteMuteRule(id: rules[index].id)
                    }
                    rules.remove(atOffsets: indexSet)
                }
            }
        }
        .navigationTitle("ミュート管理")
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
            AddMuteSheet {
                loadRules()
            }
        }
        .onAppear { loadRules() }
    }

    private func loadRules() {
        rules = (try? AppDatabase.shared.allMuteRules()) ?? []
    }
}

// MARK: - Add Mute Sheet

private struct AddMuteSheet: View {
    let onAdded: () -> Void

    @State private var muteType: MuteType = .category
    @State private var duration: MuteDuration = .permanent
    @State private var selectedValue = ""
    @State private var categories: [String] = []
    @State private var sourceNames: [String] = []
    @Environment(\.dismiss) private var dismiss

    private var currentOptions: [String] {
        muteType == .category ? categories : sourceNames
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("種類") {
                    Picker("ミュート対象", selection: $muteType) {
                        Text("カテゴリ").tag(MuteType.category)
                        Text("サイト").tag(MuteType.site)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: muteType) {
                        selectedValue = ""
                    }
                }

                Section(muteType == .category ? "カテゴリを選択" : "サイトを選択") {
                    if currentOptions.isEmpty {
                        Text("データがありません")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("選択", selection: $selectedValue) {
                            Text("未選択").tag("")
                            ForEach(currentOptions, id: \.self) { value in
                                Text(value).tag(value)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }

                Section("期間") {
                    Picker("ミュート期間", selection: $duration) {
                        ForEach(MuteDuration.allCases, id: \.self) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("ミュート追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addMute()
                    }
                    .disabled(selectedValue.isEmpty)
                }
            }
            .onAppear {
                categories = (try? AppDatabase.shared.distinctCategories()) ?? []
                sourceNames = (try? AppDatabase.shared.distinctSourceNames()) ?? []
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addMute() {
        guard !selectedValue.isEmpty else { return }
        let expiresAt: Date? = duration == .hours24
            ? Calendar.current.date(byAdding: .hour, value: 24, to: Date())
            : nil
        try? AppDatabase.shared.addMuteRule(type: muteType, value: selectedValue, expiresAt: expiresAt)
        onAdded()
        dismiss()
    }
}
