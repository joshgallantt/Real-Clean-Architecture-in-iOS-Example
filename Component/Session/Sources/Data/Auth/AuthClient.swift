import Foundation
import Session

public enum AuthClientError: Error, Equatable {
    case invalidCredentials
    case emailAlreadyInUse
    case networkFailure
    case unknown
}

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol AuthClient: Sendable {
    func login(email: Email, password: Password) async -> Result<(User, AuthToken), AuthClientError>
    func createAccount(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<(User, AuthToken), AuthClientError>
    func logout() async -> Result<Void, AuthClientError>
}
