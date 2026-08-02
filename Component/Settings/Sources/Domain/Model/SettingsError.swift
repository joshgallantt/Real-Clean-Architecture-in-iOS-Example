/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: the two outcomes a shopper can act
/// on. A disk that would not write and a request that never arrived are one fact to a shopper —
/// their setting did not change — so both collapse to `.unavailable` rather than leaking transport
/// detail inward.
public enum SettingsError: Error, Equatable, Sendable {
    case unauthenticated
    case unavailable
}
