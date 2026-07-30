import Foundation
import Session

public enum AuthClientError: Error, Equatable {
    case invalidCredentials
    case emailAlreadyInUse
    case networkFailure
    case unknown
}

public protocol AuthClient: Sendable {
    func login(email: Email, password: Password) async -> Result<(User, AuthToken), AuthClientError>
    func createAccount(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<(User, AuthToken), AuthClientError>
    func logout() async -> Result<Void, AuthClientError>
}
