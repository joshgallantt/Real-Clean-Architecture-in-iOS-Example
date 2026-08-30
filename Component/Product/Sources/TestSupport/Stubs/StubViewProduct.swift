import Money
import Product

@MainActor
public final class StubViewProduct: ViewProductUseCase {
    public var result: Result<Product, ProductError> = .success(.fixture(id: 1))
    public private(set) var calls: [ProductID] = []

    public init() {}

    public func callAsFunction(id: ProductID) async -> Result<Product, ProductError> {
        calls.append(id)
        return result
    }
}
