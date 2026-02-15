import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        List {
            Section {
                Toggle("通知を有効にする", isOn: Binding(
                    get: { settings.notificationsEnabled },
                    set: { newValue in
                        settings.notificationsEnabled = newValue
                        if newValue {
                            requestNotificationPermission()
                        }
                    }
                ))
            } footer: {
                Text("通知は最大1日1回です")
            }

            if settings.notificationsEnabled {
                Section("通知の種類") {
                    Toggle("フォロー新着", isOn: .constant(true))
                    Toggle("キーワード新着", isOn: .constant(true))
                    Toggle("朝のダイジェスト", isOn: .constant(false))
                }
            }
        }
        .navigationTitle("通知設定")
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
}
