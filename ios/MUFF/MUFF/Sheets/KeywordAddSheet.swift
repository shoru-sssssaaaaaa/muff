import SwiftUI

struct KeywordAddSheet: View {
    var initialKeyword: String
    var onAdd: ((FollowType, String) -> Void)?

    @State private var keyword = ""
    @State private var selectedType: FollowType = .keyword
    @State private var selectedValue = ""
    @State private var categories: [String] = []
    @State private var sourceNames: [String] = []
    @Environment(\.dismiss) private var dismiss

    init(initialKeyword: String, onAdd: ((FollowType, String) -> Void)? = nil) {
        self.initialKeyword = initialKeyword
        self.onAdd = onAdd
    }

    private var currentValue: String {
        selectedType == .keyword ? keyword.trimmingCharacters(in: .whitespaces) : selectedValue
    }

    private var currentOptions: [String] {
        selectedType == .category ? categories : sourceNames
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("種類") {
                    Picker("フォロータイプ", selection: $selectedType) {
                        Text("キーワード").tag(FollowType.keyword)
                        Text("カテゴリ").tag(FollowType.category)
                        Text("サイト").tag(FollowType.site)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedType) {
                        selectedValue = ""
                        keyword = ""
                    }
                }

                if selectedType == .keyword {
                    Section("値") {
                        TextField("キーワードを入力", text: $keyword)
                    }
                } else {
                    Section(selectedType == .category ? "カテゴリを選択" : "サイトを選択") {
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
                }
            }
            .navigationTitle("フォロー追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        guard !currentValue.isEmpty else { return }
                        if let onAdd {
                            onAdd(selectedType, currentValue)
                        } else {
                            try? AppDatabase.shared.addFollowRule(type: selectedType, value: currentValue)
                        }
                        dismiss()
                    }
                    .disabled(currentValue.isEmpty)
                }
            }
            .onAppear {
                keyword = initialKeyword
                categories = (try? AppDatabase.shared.distinctCategories()) ?? []
                sourceNames = (try? AppDatabase.shared.distinctSourceNames()) ?? []
            }
        }
        .presentationDetents([.medium, .large])
    }
}
