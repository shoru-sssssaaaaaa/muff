import SwiftUI

struct CategoryListView: View {
    @State private var categories: [String] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
            if categories.isEmpty && isLoading {
                LoadingView()
            } else if categories.isEmpty, let error {
                ErrorView(error) {
                    Task { await loadCategories() }
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
            if categories.isEmpty {
                await loadCategories()
            }
        }
    }

    private func loadCategories() async {
        isLoading = true
        do {
            categories = try await APIClient().fetchCategories()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
