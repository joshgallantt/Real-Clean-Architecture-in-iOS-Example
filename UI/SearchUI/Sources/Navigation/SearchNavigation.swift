import Product

public protocol SearchNavigation: AnyObject {
    func openSearchResults(query: String)
    func openCategoryResults(category: CategorySlug)
}
