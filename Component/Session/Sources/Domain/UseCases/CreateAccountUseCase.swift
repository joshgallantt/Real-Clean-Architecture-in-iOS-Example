import Foundation

public protocol CreateAccountUseCase: Sendable {
    func callAsFunction(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<Void, CreateAccountError>
}

public struct DefaultCreateAccountUseCase: CreateAccountUseCase {
    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func callAsFunction(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<Void, CreateAccountError> {
        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.nameIsMissing)
        }
        guard Email(email).isValid else { return .failure(.invalidEmail) }
        guard Password(password).isValid else { return .failure(.invalidPassword) }

        return await sessionRepository.createAccount(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password
        )
    }
}
