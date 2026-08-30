import Money
import Product

/// One thing the shop has, said the way a shopper would describe finding it.
///
/// `Sendable` because it holds only a `Product`, which is. Saying so is what
/// lets the stubs that keep stock behind a `Mutex` be `Sendable` themselves
/// rather than asking to be believed.
public struct OnTheShelf: Sendable {
    public let product: Product

    public var id: ProductID { product.id }

    public init(product: Product) {
        self.product = product
    }
}
