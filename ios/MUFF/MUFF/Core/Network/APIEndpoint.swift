import Foundation

enum APIEndpoint {
    case catalogSources
    case catalogCategories
    case feedNew(cursor: String?, limit: Int?)
    case feedPopular(limit: Int?)
    case feedCategory(category: String, cursor: String?, limit: Int?)
    case feedRefresh
    case eventsOpen
    case attestChallenge
    case attestVerify

    var path: String {
        switch self {
        case .catalogSources:
            return "/v1/catalog/sources"
        case .catalogCategories:
            return "/v1/catalog/categories"
        case .feedNew:
            return "/v1/feed/new"
        case .feedPopular:
            return "/v1/feed/popular"
        case .feedCategory(let category, _, _):
            return "/v1/feed/category/\(category)"
        case .feedRefresh:
            return "/v1/feed/refresh"
        case .eventsOpen:
            return "/v1/events/open"
        case .attestChallenge:
            return "/v1/attest/challenge"
        case .attestVerify:
            return "/v1/attest/verify"
        }
    }

    var method: String {
        switch self {
        case .feedRefresh, .eventsOpen, .attestVerify:
            return "POST"
        default:
            return "GET"
        }
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        switch self {
        case .feedNew(let cursor, let limit):
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
        case .feedPopular(let limit):
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
        case .feedCategory(_, let cursor, let limit):
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
        default:
            break
        }
        return items
    }
}
