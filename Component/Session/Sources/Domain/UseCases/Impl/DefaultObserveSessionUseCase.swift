import Combine

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
