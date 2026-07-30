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
}
