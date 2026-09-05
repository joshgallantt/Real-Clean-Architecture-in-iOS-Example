import Session

@MainActor
public final class SpyLogoutUseCase: LogoutUseCase {
    public init() {}

    public private(set) var callCount = 0

    public func callAsFunction() async {
        callCount += 1
    }
}
