import Money

/// Fowler, *PoEAA* (2002), Ch. 18 — Gateway: wraps one external system behind a domain-shaped call.
/// Whoever takes the money is asked in the domain's own terms — an amount — and answers with a name
/// for the payment or a reason there is none.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring. A
/// wallet on the device, a card form, a processor over HTTP: all of them are this protocol, and
/// nothing inward moves when which one it is changes.
public protocol PaymentClient: Sendable {
    func pay(_ amount: Money) async -> Result<PaymentReference, PaymentFailure>
}

/// What whoever took the money calls it afterwards. Opaque here on purpose — its shape belongs to
/// the processor, and the domain only ever needs to be able to quote it back.
public struct PaymentReference: Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

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
