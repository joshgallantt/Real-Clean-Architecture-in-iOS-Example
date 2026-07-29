public protocol LoginUseCase: Sendable {
    func callAsFunction(email: String, password: String) async -> Result<Void, LoginError>
}

public struct DefaultLoginUseCase: LoginUseCase {
    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    /// Checks what can be checked here before troubling the shop with it. What makes an
    /// address or a password acceptable is `Email`'s and `Password`'s to say; this only
    /// decides the order to ask in, and what to do when the answer is no.
    public func callAsFunction(email: String, password: String) async -> Result<Void, LoginError> {
        guard Email(email).isValid else { return .failure(.invalidEmail) }
        guard Password(password).isValid else { return .failure(.invalidPassword) }

        return await sessionRepository.login(email: email, password: password)
    }
}
