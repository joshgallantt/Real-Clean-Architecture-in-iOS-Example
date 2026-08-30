// Stand-ins for the protocols this package declares, so that every suite
// needing one shares a single definition rather than writing its own.

import Combine
import Product
import Wishlist

@MainActor
public final class StubObserveProductIsWishlisted: ObserveProductIsWishlistedUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Bool, Never>

    public init(_ isWishlisted: Bool = false) {
        subject = CurrentValueSubject(isWishlisted)
    }

    public func send(_ isWishlisted: Bool) { subject.value = isWishlisted }

    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}

/// `onSuccess` is how a test makes a saved product start reading as saved. The real use case writes
/// through a repository that publishes what it kept, so anything observing it has heard before the
/// call returns; a stub that only counted calls could never show a caller reading state it had not
/// yet changed. The yield is the round trip: without a suspension here every call would finish
/// before the next one could start, and no ordering would ever be at stake.
@MainActor
public final class StubSetProductIsWishlisted: SetProductIsWishlistedUseCase, @unchecked Sendable {
    public init() {}

    public var result: Result<Void, WishlistError> = .success(())
    public var onSuccess: (Bool) -> Void = { _ in }
    public private(set) var calls: [(productId: ProductID, isWishlisted: Bool)] = []

    public func callAsFunction(
        productId: ProductID,
        isWishlisted: Bool
    ) async -> Result<Void, WishlistError> {
        calls.append((productId, isWishlisted))
        await Task.yield()
        if case .success = result { onSuccess(isWishlisted) }
        return result
    }
}
