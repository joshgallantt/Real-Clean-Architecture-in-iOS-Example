import Combine

/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle.
///
/// Evans, *Domain-Driven Design* (2003) — Value Objects: speaks `Email`, `Password` and
/// `PersonName` rather than strings. Taking strings would let every implementation receive
/// something that has never been past a rule, reducing those types to validators nobody is obliged
/// to call.
///
/// Evans — Repositories. Fowler, *PoEAA* (2002) — Repository; Separated Interface.
public protocol SessionRepository: Sendable {
    @MainActor
    var sessionPublisher: AnyPublisher<Session, Never> { get }

    @MainActor
    var currentSession: Session { get }

    func login(email: Email, password: Password) async -> Result<Void, LoginError>

    func createAccount(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<Void, CreateAccountError>

    func logout() async
}
