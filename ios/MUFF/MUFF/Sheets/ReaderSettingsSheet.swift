import SwiftUI

struct ReaderSettingsSheet: View {
    @State private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
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
                }
            }
            .navigationTitle("表示設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
