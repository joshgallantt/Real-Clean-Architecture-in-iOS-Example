import Foundation

/// The bag knows ids, not products. Opening one hands the id to whoever owns the
/// catalog, which fetches that product then, and only the one the shopper opened.
public protocol BagNavigation: AnyObject {
    func openProductDetails(id: Int)
    func switchToBagTab()
}
