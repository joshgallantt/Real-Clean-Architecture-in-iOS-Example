import Combine

public protocol WishlistRepository: Sendable {
    @MainActor
    var itemsPublisher: AnyPublisher<[WishlistItem], Never> { get }

    @MainActor
    var items: [WishlistItem] { get }

    @MainActor
    func isInWishlistPublisher(productId: Int) -> AnyPublisher<Bool, Never>

    @MainActor
    func add(productId: Int)

    @MainActor
    func remove(productId: Int)
}
