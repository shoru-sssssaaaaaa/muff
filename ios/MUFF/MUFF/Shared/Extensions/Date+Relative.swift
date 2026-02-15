import Foundation

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension String {
    var dateFromISO8601: Date? {
        ISO8601DateFormatter().date(from: self)
    }

    var relativeTimeString: String {
        dateFromISO8601?.relativeString ?? self
    }
}
