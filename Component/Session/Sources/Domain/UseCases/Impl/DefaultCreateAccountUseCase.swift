/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
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

    /// Evans, *Domain-Driven Design* (2003) — Assertions: each rule is asked of the type that owns
    /// it — the name says whether it is a name, the address whether it is an address.
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
