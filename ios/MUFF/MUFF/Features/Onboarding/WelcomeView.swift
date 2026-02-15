import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "newspaper.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 12) {
                Text("MUFFへようこそ")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("速く、読みやすく、迷わない。\n自分向けに整えられるまとめリーダー")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                FeatureRow(icon: "list.bullet", title: "見やすい記事一覧", description: "大きなサムネと読みやすいレイアウト")
                FeatureRow(icon: "flame", title: "人気ランキング", description: "みんなが読んでいる記事がわかる")
                FeatureRow(icon: "slider.horizontal.3", title: "自分好みにカスタマイズ", description: "フォロー・ミュート・NGワードで整える")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
