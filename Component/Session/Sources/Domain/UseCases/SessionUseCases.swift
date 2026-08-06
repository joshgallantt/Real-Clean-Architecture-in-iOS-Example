import Combine

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything the application can ask about who is signed in. Those three hold for every protocol
// below, so they are cited once; a comment on any one of them says only what is true of that one.

public protocol CreateAccountUseCase: Sendable {
    func callAsFunction(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<Void, CreateAccountError>
}

public protocol GetSessionUseCase: Sendable {
    @MainActor
    func callAsFunction() -> Session
}

public protocol LoginUseCase: Sendable {
    func callAsFunction(email: Email, password: Password) async -> Result<Void, LoginError>
}

public protocol LogoutUseCase: Sendable {
    func callAsFunction() async
}

public protocol ObserveSessionUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Session, Never>
}
