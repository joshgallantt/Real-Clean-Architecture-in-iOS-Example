import Foundation

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    public func get<T: Decodable>(_ url: URL) async throws -> T {
        try await send(URLRequest(url: url))
    }

    public func post<Body: Encodable, T: Decodable>(_ url: URL, body: Body) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw HTTPClientError.transport
        }
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw HTTPClientError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HTTPClientError.decoding
        }
    }
}
