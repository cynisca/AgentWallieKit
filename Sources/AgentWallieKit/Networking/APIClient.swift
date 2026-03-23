import Foundation

/// HTTP client for communicating with the AgentWallie backend.
public final class APIClient: @unchecked Sendable {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession

    public init(apiKey: String, baseURL: URL, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }

    /// Fetch the compiled SDK config.
    public func fetchConfig() async throws -> SDKConfig {
        let url = baseURL.appendingPathComponent("v1/config/\(apiKey)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(SDKConfig.self, from: data)
        } catch {
            #if DEBUG
            // Log the raw JSON (truncated) and the decode error for debugging
            let preview = String(data: data.prefix(500), encoding: .utf8) ?? "(binary)"
            print("[AgentWallie] [error] Config decode failed. Response preview: \(preview)...")
            print("[AgentWallie] [error] Decode error: \(error)")
            #endif
            throw APIError.decodingError(error)
        }
    }

    /// Post analytics events to the backend.
    public func postEvents(_ events: [AnalyticsEvent]) async throws {
        let url = baseURL.appendingPathComponent("v1/events/\(apiKey)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(["events": events])

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode)
        }
    }
}

/// API errors.
public enum APIError: Error, Sendable {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
}
