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
