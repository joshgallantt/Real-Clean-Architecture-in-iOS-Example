/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: stated in the domain's
/// vocabulary, not the storage's.
///
/// `.unauthenticated` because being told when something is back requires somewhere to tell them,
/// and a guest has not said where. `.unavailable` is deliberately one case: a disk that would not
/// write, a request that never arrived and an unreadable payload are the same fact to a shopper —
/// nobody has promised them anything — and nothing in the domain would act on the difference.
public enum StockAlertError: Error, Equatable, Sendable {
    case unauthenticated
    case unavailable
}
