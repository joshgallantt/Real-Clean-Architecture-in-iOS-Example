public protocol LogoutUseCase: Sendable {
    func execute() async
}

public struct DefaultLogoutUseCase: LogoutUseCase {
    let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() async {
        await sessionRepository.logout()
    }
}
