import Foundation
import Product

/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: the feature
/// declares the moves it needs; the app layer conforms. The feature never learns what a destination
/// is or which tab it sits in.
///
/// Fowler, *PoEAA* (2002) — Separated Interface. Martin, Ch. 10 — Interface Segregation Principle:
/// one protocol per feature, so nothing depends on another feature's routes.
public protocol WishlistNavigation: AnyObject {
    func openProductDetails(product: Product)

    /// The two View Alls. Named for the lists a shopper sees rather than for the components behind
    /// them, because this tab is where a wishlist and a set of stock alerts stop being two things
    /// and start being "what I am keeping an eye on".
    func openAllFaves()
    func openAllNotifyMe()
}
