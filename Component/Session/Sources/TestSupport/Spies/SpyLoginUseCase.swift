import Session

@MainActor
public final class SpyLoginUseCase: LoginUseCase {
    public init() {}

    public var result: Result<Void, LoginError> = .success(())
    public private(set) var calls: [(email: Email, password: Password)] = []

    public func callAsFunction(email: Email, password: Password) async -> Result<Void, LoginError> {
        calls.append((email, password))
        return result
    }
}
