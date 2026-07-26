import Product

public protocol HomeNavigation: AnyObject {
    func openProductDetails(product: Product)
}
