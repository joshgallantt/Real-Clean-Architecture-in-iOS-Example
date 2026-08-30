import Money
import Product

/// Answers whatever it was told to, and remembers what it was asked. Kept apart
/// from `StubCatalog` deliberately: this one is about the answer, that one is
/// about the shop, and a test reads differently depending on which it needs.
@MainActor
public final class StubLookUpProducts: LookUpProductsUseCase {
    public var result: Result<[Product], ProductError> = .success([])
    public private(set) var asked: [[ProductID]] = []

    public init() {}

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        asked.append(ids)
        return result
    }
}
