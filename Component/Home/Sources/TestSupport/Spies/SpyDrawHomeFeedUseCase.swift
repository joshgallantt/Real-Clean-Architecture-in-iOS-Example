import Home

@MainActor
public final class SpyDrawHomeFeedUseCase: DrawHomeFeedUseCase {
    public init() {}

    public var result: Result<HomeFeed, HomeError> = .failure(.unavailable)
    public private(set) var callCount = 0

    public func callAsFunction() async -> Result<HomeFeed, HomeError> {
        callCount += 1
        return result
    }
}
