import SwiftUI
import FeedKit

struct AddRSSView: View {
    let onAdded: () -> Void

    @State private var rssURL = ""
    @State private var name = ""
    @State private var selectedCategory = "ニュース"
    @State private var isValidating = false
    @State private var error: String?
    @State private var validatedFeedTitle: String?
    @Environment(\.dismiss) private var dismiss

    private let categories = ["ニュース", "芸能", "スポーツ", "ゲーム", "アニメ", "IT", "生活", "その他"]

    var body: some View {
        Form {
            Section("RSS URL") {
                TextField("https://example.com/rss", text: $rssURL)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocapitalization(.none)

                if isValidating {
                    HStack {
                        ProgressView()
                        Text("検証中...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let feedTitle = validatedFeedTitle {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(feedTitle)
                            .font(.caption)
                    }
                }
            }

            Section("設定") {
                TextField("ソース名", text: $name)

                Picker("カテゴリ", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
            }

            Section {
                Button("検証") {
                    Task { await validateFeed() }
                }
                .disabled(rssURL.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)

                Button("追加") {
                    addSource()
                }
                .disabled(validatedFeedTitle == nil || name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("RSS追加")
    }

    private func validateFeed() async {
        isValidating = true
        error = nil
        validatedFeedTitle = nil

        guard let url = URL(string: rssURL.trimmingCharacters(in: .whitespaces)) else {
            error = "無効なURLです"
            isValidating = false
            return
        }

        let parser = FeedParser(URL: url)
        let result: Result<Feed, ParserError> = await withCheckedContinuation { continuation in
            parser.parseAsync { result in
                nonisolated(unsafe) let r = result
                continuation.resume(returning: r)
            }
        }

        switch result {
        case .success(let feed):
            switch feed {
            case .rss(let rssFeed):
                validatedFeedTitle = rssFeed.title ?? "RSS Feed"
                if name.isEmpty { name = rssFeed.title ?? "" }
            case .atom(let atomFeed):
                validatedFeedTitle = atomFeed.title ?? "Atom Feed"
                if name.isEmpty { name = atomFeed.title ?? "" }
            case .json(let jsonFeed):
                validatedFeedTitle = jsonFeed.title ?? "JSON Feed"
                if name.isEmpty { name = jsonFeed.title ?? "" }
            }
        case .failure(let parseError):
            error = "フィードの解析に失敗: \(parseError.localizedDescription)"
        }

        isValidating = false
    }

    private func addSource() {
        let source = UserSource(
            name: name.trimmingCharacters(in: .whitespaces),
            rssUrl: rssURL.trimmingCharacters(in: .whitespaces),
            siteUrl: rssURL.trimmingCharacters(in: .whitespaces),
            category: selectedCategory
        )
        try? AppDatabase.shared.addUserSource(source)
        onAdded()
        dismiss()
    }
}
