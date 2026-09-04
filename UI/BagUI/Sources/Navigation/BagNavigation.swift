import Foundation
import Product

/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: the feature
/// declares the moves it needs; the app layer conforms. The feature never learns what a destination
/// is or which tab it sits in.
///
/// Fowler, *PoEAA* (2002), Ch. 18 — Separated Interface. Martin, Ch. 10 — Interface Segregation Principle:
/// one protocol per feature, so nothing depends on another feature's routes.
public protocol BagNavigation: AnyObject {
    /// The product itself, never its id. A route that took an id would let this screen ask for a
    /// page it has no product for, and the app layer would have to go and find one — a second
    /// lookup of something the bag has already been told, on a path nothing here could test.
    func openProductDetails(product: Product)
}
