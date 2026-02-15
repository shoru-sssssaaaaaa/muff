import SwiftUI

struct ReaderSettingsView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        List {
            Section("Readerモード") {
                Toggle("デフォルトでReaderモード", isOn: Binding(
                    get: { settings.readerModeEnabled },
                    set: { settings.readerModeEnabled = $0 }
                ))

                Text("Readerモードでは、記事の本文を抽出して読みやすく表示します。抽出に失敗した場合は自動的にWeb表示に戻ります。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("フォントサイズ") {
                HStack {
                    Text("A")
                        .font(.caption)
                    Slider(value: Binding(
                        get: { settings.readerFontSize },
                        set: { settings.readerFontSize = $0 }
                    ), in: 12...24, step: 1)
                    Text("A")
                        .font(.title2)
                }

                Text("現在: \(Int(settings.readerFontSize))pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("行間") {
                HStack {
                    Text("狭い")
                        .font(.caption)
                    Slider(value: Binding(
                        get: { settings.readerLineSpacing },
                        set: { settings.readerLineSpacing = $0 }
                    ), in: 1.0...2.5, step: 0.1)
                    Text("広い")
                        .font(.caption)
                }

                Text("現在: \(settings.readerLineSpacing, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Reader設定")
    }
}
