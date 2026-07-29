import Foundation
import Networking

/// Stubs one exact request at a time and refuses anything it was not told about, so a
/// test that stops making the request it claims to make fails loudly instead of
/// quietly passing. Decodes the stubbed body itself, exactly as `URLSessionHTTPClient`
/// does, so the repository's tests run the real parsing.
final class StubHTTPClient: HTTPClient, @unchecked Sendable {
    enum StubError: Error, CustomStringConvertible {
        case noStubFor(URL)

        var description: String {
            switch self {
            case .noStubFor(let url): "no stubbed response for \(url.absoluteString)"
            }
        }
    }

    private struct Stub {
        let path: String
        let query: [String: String]
        let outcome: Result<Data, Error>

        func matches(_ url: URL) -> Bool {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  components.path == path
            else {
                return false
            }

            let items = Dictionary(
                uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
            )
            return query.allSatisfy { items[$0.key] == $0.value }
        }
    }

    private let lock = NSLock()
    private var stubs: [Stub] = []
    private var _requestedURLs: [URL] = []

    var requestedURLs: [URL] { lock.withLock { _requestedURLs } }
    var lastRequest: URL? { requestedURLs.last }

    func stub(path: String, query: [String: String] = [:], returning json: String) {
        lock.withLock { stubs.append(Stub(path: path, query: query, outcome: .success(Data(json.utf8)))) }
    }

    func stub(path: String, query: [String: String] = [:], failingWith error: Error) {
        lock.withLock { stubs.append(Stub(path: path, query: query, outcome: .failure(error))) }
    }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let outcome = lock.withLock { () -> Result<Data, Error> in
            _requestedURLs.append(url)
            let stub = stubs.first { $0.matches(url) }
            return stub?.outcome ?? .failure(StubError.noStubFor(url))
        }

        let data = try outcome.get()
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HTTPClientError.decoding
        }
    }

    func post<Body: Encodable, T: Decodable>(_ url: URL, body: Body) async throws -> T {
        throw HTTPClientError.server(statusCode: 405)
    }
}

extension URL {
    var requestPath: String { URLComponents(url: self, resolvingAgainstBaseURL: false)?.path ?? "" }

    /// The query as an unordered set, so a reordering by `URLComponents` stays a
    /// refactor rather than a failure.
    var requestQuery: [String: String] {
        let items = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }
}
