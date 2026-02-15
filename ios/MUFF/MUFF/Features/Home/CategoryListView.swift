import SwiftUI

struct CategoryListView: View {
    @State private var sources: [SourceResponse] = []
    @State private var isLoading = false
    @State private var error: String?

    private var categories: [String] {
        Array(Set(sources.map(\.defaultCategory))).sorted()
    }

    var body: some View {
        Group {
            if categories.isEmpty && isLoading {
                LoadingView()
            } else if categories.isEmpty, let error {
                ErrorView(error) {
                    Task { await loadSources() }
                }
            } else {
                List(categories, id: \.self) { category in
                    NavigationLink(value: category) {
                        HStack {
                            Text(category)
                                .font(.body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationDestination(for: String.self) { category in
            CategoryFeedView(category: category)
        }
        .task {
            if sources.isEmpty {
                await loadSources()
            }
        }
    }

    private func loadSources() async {
        isLoading = true
        do {
            sources = try await APIClient().fetchSources()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
