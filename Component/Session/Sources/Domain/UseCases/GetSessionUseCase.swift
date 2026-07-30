/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol GetSessionUseCase: Sendable {
    @MainActor
    func callAsFunction() -> Session
}

public struct DefaultGetSessionUseCase: GetSessionUseCase {
    let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    @MainActor
    public func callAsFunction() -> Session {
        sessionRepository.currentSession
    }
}
