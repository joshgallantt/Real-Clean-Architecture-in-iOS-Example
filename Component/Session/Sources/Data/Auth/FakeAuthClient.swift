import Foundation
import CryptoKit
import Session

public struct FakeAuthClient: AuthClient {
    private let userStore: UserStore
    private let tokenLifetime: TimeInterval

    public init(userStore: UserStore, tokenLifetime: TimeInterval) {
        self.userStore = userStore
        self.tokenLifetime = tokenLifetime
    }

    public func login(email: Email, password: Password) async -> Result<(User, AuthToken), AuthClientError> {
        guard email.isValid, password.isValid else {
            return .failure(.invalidCredentials)
        }
        guard let record = userStore.find(email: email.value) else {
            return .failure(.invalidCredentials)
        }
        guard record.passwordHash == hash(password.value) else {
            return .failure(.invalidCredentials)
        }
        return .success(makeSession(from: record))
    }

    public func createAccount(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<(User, AuthToken), AuthClientError> {
        guard name.isValid, email.isValid, password.isValid else {
            return .failure(.unknown)
        }
        guard userStore.find(email: email.value) == nil else {
            return .failure(.emailAlreadyInUse)
        }
        let record = StoredUser(
            id: stableId(for: email.value),
            email: email.value,
            firstName: name.first,
            lastName: name.last ?? "",
            passwordHash: hash(password.value)
        )
        userStore.save(record)
        return .success(makeSession(from: record))
    }

    public func logout() async -> Result<Void, AuthClientError> {
        .success(())
    }

    private func makeSession(from record: StoredUser) -> (User, AuthToken) {
        let user = User(
            id: UserID(rawValue: record.id),
            email: Email(record.email),
            name: PersonName(first: record.firstName, last: record.lastName)
        )
        let token = AuthToken(value: UUID().uuidString, expiresAt: Date().addingTimeInterval(tokenLifetime))
        return (user, token)
    }

    private func hash(_ password: String) -> String {
        SHA256.hash(data: Data(password.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func stableId(for email: String) -> Int {
        var hash = 5381
        for byte in email.lowercased().utf8 {
            hash = (hash &* 33) &+ Int(byte)
        }
        return hash & .max
    }
}
