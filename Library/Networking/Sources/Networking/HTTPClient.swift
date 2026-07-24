import Foundation

public enum HTTPClientError: Error, Equatable, Sendable {
    case transport
    case decoding
    case server(statusCode: Int)
}

public protocol HTTPClient: Sendable {
    func get<T: Decodable>(_ url: URL) async throws -> T
    func post<Body: Encodable, T: Decodable>(_ url: URL, body: Body) async throws -> T
}
