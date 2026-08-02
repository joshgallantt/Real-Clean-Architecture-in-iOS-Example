import Home
import Product

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. Home
/// takes the two Product use cases already resolved rather than a repository — Home owns no storage
/// of its own, so it has none to wire. Not unit tested — there is no behaviour here to test.
public struct HomeDI {
    public let drawHomeFeedUseCase: DrawHomeFeedUseCase

    public init(browseCatalog: BrowseCatalogUseCase, browseCategories: BrowseCategoriesUseCase) {
        self.drawHomeFeedUseCase = DefaultDrawHomeFeedUseCase(
            browseCatalog: browseCatalog,
            browseCategories: browseCategories
        )
    }
}
