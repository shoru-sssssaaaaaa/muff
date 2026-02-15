import SwiftUI
import NukeUI

struct ArticleCardView: View {
    let article: ArticleResponse
    let isRead: Bool
    let ngWarning: String?

    private var settings: AppSettings { AppSettings.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // NG warning label
            if let ngWarning {
                Label("注意: \"\(ngWarning)\"", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack(alignment: .top, spacing: 12) {
                // Thumbnail
                if settings.showThumbnails, let thumbnailUrl = article.thumbnailUrl,
                   let url = URL(string: thumbnailUrl) {
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                    }
                    .frame(width: 100, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Category + Source
                    HStack(spacing: 4) {
                        Text(article.category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())

                        Text(article.sourceName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Title
                    Text(article.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(3)

                    // Metadata row
                    HStack(spacing: 8) {
                        if let viewCount = article.viewCount {
                            Label("\(viewCount)", systemImage: "eye")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Text(article.publishedAt.relativeTimeString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(isRead && settings.readArticleDisplayMode == .dim ? 0.5 : 1.0)
        .contentShape(Rectangle())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
    }
}
