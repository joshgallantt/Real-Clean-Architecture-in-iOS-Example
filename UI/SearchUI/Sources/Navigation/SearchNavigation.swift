import Product

public protocol SearchNavigation: AnyObject {
    func openCatalog(filter: CatalogFilter)
    func openProductDetails(product: Product)
}
