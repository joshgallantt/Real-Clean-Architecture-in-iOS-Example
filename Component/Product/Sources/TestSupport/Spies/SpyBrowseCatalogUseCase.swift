import Money
import Product

@MainActor
public final class SpyBrowseCatalogUseCase: BrowseCatalogUseCase {
    public var result: Result<[Product], ProductError> = .success([])
    public private(set) var queries: [CatalogQuery] = []

    public init() {}

    public func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        queries.append(query)
        return result
    }
}
