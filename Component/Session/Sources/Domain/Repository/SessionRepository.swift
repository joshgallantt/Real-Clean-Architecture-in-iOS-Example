import Combine

/// Whether anyone is signed in, and the ways that changes.
///
/// Speaks `Email`, `Password` and `PersonName` rather than strings. The rules about what
/// those may contain exist a layer inward; taking them as strings here means every
/// implementation is free to receive something that has never been past a rule, and the
/// types are reduced to validators nobody is obliged to call.
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
