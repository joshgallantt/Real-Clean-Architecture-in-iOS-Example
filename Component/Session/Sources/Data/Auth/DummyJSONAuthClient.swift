import Foundation
import Networking
import Session

public struct DummyJSONAuthClient: AuthClient {
    private let httpClient: HTTPClient
    private let baseURL = URL(string: "https://dummyjson.com")!
    private let tokenLifetime: TimeInterval

    public init(httpClient: HTTPClient, tokenLifetime: TimeInterval) {
        self.httpClient = httpClient
        self.tokenLifetime = tokenLifetime
    }

    public func login(username: String, password: String) async -> Result<(User, AuthToken), AuthClientError> {
        let request = LoginRequestDTO(username: username, password: password, expiresInMins: max(1, Int(tokenLifetime / 60)))
        do {
            let response: LoginResponseDTO = try await httpClient.post(baseURL.appendingPathComponent("auth/login"), body: request)
            let user = User(
                id: response.id,
                username: response.username,
                email: response.email,
                firstName: response.firstName,
                lastName: response.lastName
            )
            let token = AuthToken(value: response.accessToken, expiresAt: Date().addingTimeInterval(tokenLifetime))
            return .success((user, token))
        } catch HTTPClientError.server(let statusCode) where statusCode == 400 || statusCode == 401 {
            return .failure(.invalidCredentials)
        } catch HTTPClientError.transport {
            return .failure(.networkFailure)
        } catch {
            return .failure(.unknown)
        }
    }

    public func logout() async -> Result<Void, AuthClientError> {
        .success(())
    }
}
