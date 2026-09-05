import Session

@MainActor
public final class SpyCreateAccountUseCase: CreateAccountUseCase {
    public init() {}

    public var result: Result<Void, CreateAccountError> = .success(())
    public private(set) var calls: [(name: PersonName, email: Email, password: Password)] = []

    public func callAsFunction(name: PersonName, email: Email, password: Password) async -> Result<Void, CreateAccountError> {
        calls.append((name, email, password))
        return result
    }
}
