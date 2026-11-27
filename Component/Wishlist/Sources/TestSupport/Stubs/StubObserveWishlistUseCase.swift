import Combine
import Wishlist

@MainActor
public final class StubObserveWishlistUseCase: ObserveWishlistUseCase {
    private let subject = CurrentValueSubject<Wishlist, Never>(Wishlist())

    public init() {}

    public func send(_ wishlist: Wishlist) { subject.send(wishlist) }

    public func callAsFunction() -> AnyPublisher<Wishlist, Never> { subject.eraseToAnyPublisher() }
}
