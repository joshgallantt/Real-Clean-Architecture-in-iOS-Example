import Money

/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Services: an operation the business needs that
/// belongs to no entity or value object, declared in the domain and satisfied outside it.
///
/// Named for what the business needs done rather than for whatever does it. A `PaymentClient` would
/// say there is a client of something out there; the domain has no opinion about that, and once it
/// holds a `Client`, an `API` and a `Cache` nobody can tell which of them are business rules.
/// Whoever takes the money is asked in the domain's own terms — an amount — and answers with a name
/// for the payment or a reason there is none.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring. A
/// wallet on the device, a card form, a processor over HTTP: all of them are this protocol, and
/// nothing inward moves when which one it is changes.
public protocol PaymentService: Sendable {
    func pay(_ amount: Money) async -> Result<PaymentReference, PaymentFailure>
}
