/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: stated in the domain's
/// vocabulary, not the processor's or the storage's.
///
/// `.unauthenticated` because an order has to belong to somebody — there is nowhere to send it and
/// nowhere to list it otherwise, and unlike a bag a guest cannot hold one. `.nothingToOrder` is its
/// own case rather than a silent success, because a screen that offers to buy nothing has a bug in
/// it and should be told so. `.paymentDeclined` is kept apart from `.unavailable` for the same
/// reason `PaymentFailure` keeps them apart: one is worth paying another way, the other is worth
/// trying again.
public enum OrderError: Error, Equatable, Sendable {
    case unauthenticated
    case nothingToOrder
    case paymentDeclined
    case unavailable
}
