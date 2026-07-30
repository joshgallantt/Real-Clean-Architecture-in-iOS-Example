import Combine

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveSessionUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Session, Never>
}

public struct DefaultObserveSessionUseCase: ObserveSessionUseCase {
    let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<Session, Never> {
        sessionRepository.sessionPublisher
    }
}
