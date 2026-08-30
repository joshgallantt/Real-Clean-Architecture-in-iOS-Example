import Money
import Product

/// Records that it was asked, as well as answering. The merge of two copies,
/// one of which counted its calls and one of which did not — and the count is
/// the only reason a test would reach for this rather than a plain answer.
///
/// Not `@MainActor`, though one of the two copies was. Isolation that suited
/// the package which happened to write it stops the double being usable as a
/// default argument anywhere nonisolated — a constraint the protocol never
/// asked for, inherited from whoever got there first.
@MainActor
public final class SpyBrowseCategories: BrowseCategoriesUseCase {
    public var result: Result<[ProductCategory], ProductError> = .success([])
    public private(set) var callCount = 0

    public init() {}

    public func callAsFunction() async -> Result<[ProductCategory], ProductError> {
        callCount += 1
        return result
    }
}
