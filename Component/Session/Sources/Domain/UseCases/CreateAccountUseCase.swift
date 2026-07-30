public protocol CreateAccountUseCase: Sendable {
    func callAsFunction(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<Void, CreateAccountError>
}

public struct DefaultCreateAccountUseCase: CreateAccountUseCase {
    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    /// Checks what can be checked here before troubling the shop with it. Each rule is
    /// asked of the thing that owns it — the name says whether it is a name, the address
    /// whether it is an address — so this decides only the order to ask in, and there is no
    /// half of a rule left here to forget.
    public func callAsFunction(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<Void, CreateAccountError> {
        guard name.isValid else { return .failure(.nameIsMissing) }
        guard email.isValid else { return .failure(.invalidEmail) }
        guard password.isValid else { return .failure(.invalidPassword) }

        return await sessionRepository.createAccount(name: name, email: email, password: password)
    }
}
