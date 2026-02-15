import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(Int, ErrorResponse?)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let code, let response):
            return response?.message ?? "サーバーエラー (\(code))"
        case .decodingError(let error):
            return "データ解析エラー: \(error.localizedDescription)"
        }
    }
}

final class APIClient: Sendable {
    let baseURL: String

    init(baseURL: String = "http://localhost:8080") {
        self.baseURL = baseURL
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    private func buildRequest(endpoint: APIEndpoint, body: Data? = nil) throws -> URLRequest {
        var components = URLComponents(string: baseURL + endpoint.path)
        let queryItems = endpoint.queryItems
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.serverError(httpResponse.statusCode, errorResponse)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Public API

    func fetchSources() async throws -> [SourceResponse] {
        let request = try buildRequest(endpoint: .catalogSources)
        return try await perform(request)
    }

    func fetchNewFeed(cursor: String? = nil, limit: Int? = nil) async throws -> FeedResponse {
        let request = try buildRequest(endpoint: .feedNew(cursor: cursor, limit: limit))
        return try await perform(request)
    }

    func fetchPopularFeed(limit: Int? = nil) async throws -> FeedResponse {
        let request = try buildRequest(endpoint: .feedPopular(limit: limit))
        return try await perform(request)
    }

    func fetchCategoryFeed(category: String, cursor: String? = nil, limit: Int? = nil) async throws -> FeedResponse {
        let request = try buildRequest(endpoint: .feedCategory(category: category, cursor: cursor, limit: limit))
        return try await perform(request)
    }

    func postOpenEvent(_ event: OpenEventRequest) async throws {
        let body = try encoder.encode(event)
        let request = try buildRequest(endpoint: .eventsOpen, body: body)
        let _: StatusResponse = try await perform(request)
    }
}
