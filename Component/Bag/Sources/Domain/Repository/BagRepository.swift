import Combine

public protocol BagRepository: Sendable {
    @MainActor
    var itemsPublisher: AnyPublisher<[BagItem], Never> { get }

    @MainActor
    var items: [BagItem] { get }

    @MainActor
    func quantityPublisher(productId: Int) -> AnyPublisher<Int, Never>

    @MainActor
    func add(productId: Int)

    @MainActor
    func remove(productId: Int)

    @MainActor
    func updateQuantity(productId: Int, quantity: Int)
}
