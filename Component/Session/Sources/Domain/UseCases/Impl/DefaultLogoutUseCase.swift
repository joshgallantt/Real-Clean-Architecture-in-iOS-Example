public struct DefaultLogoutUseCase: LogoutUseCase {
    let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func callAsFunction() async {
        await sessionRepository.logout()
    }
}
