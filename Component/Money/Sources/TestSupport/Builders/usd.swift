import Foundation
import Money

/// An amount in dollars, for a test that cares about the number and not the
/// currency.
///
/// A builder belongs to the package that declares the type it builds, for the
/// same reason a double belongs to the package that declares its protocol. This
/// one had been written seven times, six of them byte for byte.
public func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}
