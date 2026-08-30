import Money
import Product

/// Answers differently per category, for a screen that draws several at once.
@MainActor
public final class StubBrowseCatalogByCategory: BrowseCatalogUseCase {
    public var resultsByCategory: [CategoryID: Result<[Product], ProductError>] = [:]
    public private(set) var queries: [CatalogQuery] = []

    public init() {}

    public func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        queries.append(query)
        guard case .category(let category) = query.filter else { return .success([]) }
        return resultsByCategory[category.id] ?? .success([])
    }
}
