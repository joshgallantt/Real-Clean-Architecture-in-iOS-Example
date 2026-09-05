import Combine
import Product
import Wishlist

@MainActor
public final class StubObserveProductIsWishlistedUseCase: ObserveProductIsWishlistedUseCase {
    private let subject: CurrentValueSubject<Bool, Never>

    public init(_ isWishlisted: Bool = false) {
        subject = CurrentValueSubject(isWishlisted)
    }

    public func send(_ isWishlisted: Bool) { subject.value = isWishlisted }

    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}
