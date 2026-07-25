public protocol RequireAuthenticationUseCase: Sendable {
    @MainActor
    func callAsFunction() async -> Bool
}

public struct DefaultRequireAuthenticationUseCase: RequireAuthenticationUseCase {
    private let getSession: GetSessionUseCase

    public init(getSession: GetSessionUseCase) {
        self.getSession = getSession
    }

    @MainActor
    public func callAsFunction() async -> Bool {
        getSession().isLoggedIn
    }
}
