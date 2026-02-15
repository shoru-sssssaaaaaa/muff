import Foundation
import SwiftUI

enum ReadArticleDisplayMode: String, CaseIterable, Sendable {
    case dim = "薄表示"
    case collapse = "折りたたみ"
    case hide = "非表示"
}

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    var readArticleDisplayMode: ReadArticleDisplayMode {
        didSet { defaults.set(readArticleDisplayMode.rawValue, forKey: "readArticleDisplayMode") }
    }

    var showThumbnails: Bool {
        didSet { defaults.set(showThumbnails, forKey: "showThumbnails") }
    }

    var readerModeEnabled: Bool {
        didSet { defaults.set(readerModeEnabled, forKey: "readerModeEnabled") }
    }

    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    var readerFontSize: Double {
        didSet { defaults.set(readerFontSize, forKey: "readerFontSize") }
    }

    var readerLineSpacing: Double {
        didSet { defaults.set(readerLineSpacing, forKey: "readerLineSpacing") }
    }

    var hideLinkTables: Bool {
        didSet { defaults.set(hideLinkTables, forKey: "hideLinkTables") }
    }

    var hideLinkedImages: Bool {
        didSet { defaults.set(hideLinkedImages, forKey: "hideLinkedImages") }
    }

    var adBlockEnabled: Bool {
        didSet { defaults.set(adBlockEnabled, forKey: "adBlockEnabled") }
    }

    var darkModeEnabled: Bool {
        didSet { defaults.set(darkModeEnabled, forKey: "darkModeEnabled") }
    }

    var disabledDefaultSourceIds: Set<String> {
        didSet { defaults.set(Array(disabledDefaultSourceIds), forKey: "disabledDefaultSourceIds") }
    }

    private init() {
        let d = UserDefaults.standard
        self.hasCompletedOnboarding = d.bool(forKey: "hasCompletedOnboarding")

        let rawMode = d.string(forKey: "readArticleDisplayMode") ?? ReadArticleDisplayMode.dim.rawValue
        self.readArticleDisplayMode = ReadArticleDisplayMode(rawValue: rawMode) ?? .dim

        self.showThumbnails = d.object(forKey: "showThumbnails") as? Bool ?? true
        self.readerModeEnabled = d.bool(forKey: "readerModeEnabled")
        self.notificationsEnabled = d.bool(forKey: "notificationsEnabled")
        self.readerFontSize = d.object(forKey: "readerFontSize") as? Double ?? 16.0
        self.readerLineSpacing = d.object(forKey: "readerLineSpacing") as? Double ?? 1.5
        self.hideLinkTables = d.object(forKey: "hideLinkTables") as? Bool ?? true
        self.hideLinkedImages = d.object(forKey: "hideLinkedImages") as? Bool ?? true
        self.adBlockEnabled = d.object(forKey: "adBlockEnabled") as? Bool ?? true
        self.darkModeEnabled = d.bool(forKey: "darkModeEnabled")
        self.disabledDefaultSourceIds = Set(d.stringArray(forKey: "disabledDefaultSourceIds") ?? [])
    }
}
