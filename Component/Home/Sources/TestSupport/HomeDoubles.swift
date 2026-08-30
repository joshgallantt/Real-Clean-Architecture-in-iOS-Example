// Stand-ins for the protocols this package declares, so that every suite
// needing one shares a single definition rather than writing its own.

import Home

@MainActor
public final class StubDrawHomeFeed: DrawHomeFeedUseCase, @unchecked Sendable {
    public init() {}

    public var result: Result<HomeFeed, HomeError> = .failure(.unavailable)
    public private(set) var callCount = 0

    public func callAsFunction() async -> Result<HomeFeed, HomeError> {
        callCount += 1
        return result
    }
}
