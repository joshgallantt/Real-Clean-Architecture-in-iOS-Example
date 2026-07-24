public protocol GetSessionUseCase: Sendable {
    @MainActor
    func execute() -> Session
}

public struct DefaultGetSessionUseCase: GetSessionUseCase {
    let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    @MainActor
    public func execute() -> Session {
        sessionRepository.currentSession
    }
}
