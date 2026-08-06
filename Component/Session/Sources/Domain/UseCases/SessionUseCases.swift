import Combine

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

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol GetSessionUseCase: Sendable {
    @MainActor
    func callAsFunction() -> Session
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol LoginUseCase: Sendable {
    func callAsFunction(email: Email, password: Password) async -> Result<Void, LoginError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol LogoutUseCase: Sendable {
    func callAsFunction() async
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveSessionUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Session, Never>
}
