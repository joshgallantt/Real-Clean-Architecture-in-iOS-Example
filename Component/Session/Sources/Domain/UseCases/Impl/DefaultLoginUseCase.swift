/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol LoginUseCase: Sendable {
    func callAsFunction(email: Email, password: Password) async -> Result<Void, LoginError>
}

public struct DefaultLoginUseCase: LoginUseCase {
    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    /// Evans, *Domain-Driven Design* (2003) — Assertions: each rule is asked of the type that owns
    /// it. This decides only the order to ask in, so no half of a rule is left here to forget.
    public func callAsFunction(email: Email, password: Password) async -> Result<Void, LoginError> {
        guard email.isValid else { return .failure(.invalidEmail) }
        guard password.isValid else { return .failure(.invalidPassword) }

        return await sessionRepository.login(email: email, password: password)
    }
}
