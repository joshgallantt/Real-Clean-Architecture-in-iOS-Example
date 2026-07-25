public protocol CreateAccountUseCase: Sendable {
    func callAsFunction(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<Void, CreateAccountError>
}

public struct DefaultCreateAccountUseCase: CreateAccountUseCase {
    let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func callAsFunction(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<Void, CreateAccountError> {
        if firstName.isEmpty {
            return .failure(.firstNameIsEmpty)
        }
        if email.isEmpty {
            return .failure(.emailIsEmpty)
        }
        if password.isEmpty {
            return .failure(.passwordIsEmpty)
        }
        return await sessionRepository.createAccount(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password
        )
    }
}
