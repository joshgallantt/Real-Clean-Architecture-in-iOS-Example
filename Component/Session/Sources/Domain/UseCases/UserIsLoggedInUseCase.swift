public protocol UserIsLoggedInUseCase: Sendable {
    @MainActor
    func callAsFunction() async -> Bool
}

public struct DefaultUserIsLoggedInUseCase: UserIsLoggedInUseCase {
    private let getSession: GetSessionUseCase

    public init(getSession: GetSessionUseCase) {
        self.getSession = getSession
    }

    @MainActor
    public func callAsFunction() async -> Bool {
        getSession().isLoggedIn
    }
}
