/// Martin, *Clean Architecture* (2017), Ch. 10 — Interface Segregation Principle: the payment
/// port's failures are payment failures. It has no opinion on whether the shopper was signed in or
/// whether there was anything to buy, so `OrderError` is not what it returns.
///
/// Two cases because a shopper does two different things about them: a decline is worth trying
/// another way to pay, and everything else is worth trying again later.
public enum PaymentFailure: Error, Equatable, Sendable {
    case declined
    case unavailable
}
