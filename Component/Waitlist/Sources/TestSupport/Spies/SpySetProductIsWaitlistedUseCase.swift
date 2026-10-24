import Product
import Waitlist

/// `onSuccess` is how a test makes a waitlisted product start reading as waitlisted. The real use
/// case writes through a repository that publishes what it kept, so anything observing it has heard
/// before the call returns. The yield is the round trip: without a suspension here every call would
/// finish before the next one could start, and no ordering would ever be at stake.
@MainActor
public final class SpySetProductIsWaitlistedUseCase: SetProductIsWaitlistedUseCase {
    public init() {}

    public var result: Result<Void, WaitlistError> = .success(())
    public var onSuccess: (Bool) -> Void = { _ in }
    public private(set) var calls: [(productId: ProductID, isWaitlisted: Bool)] = []

    public func callAsFunction(
        productId: ProductID,
        isWaitlisted: Bool
    ) async -> Result<Void, WaitlistError> {
        calls.append((productId, isWaitlisted))
        await Task.yield()
        if case .success = result { onSuccess(isWaitlisted) }
        return result
    }
}
