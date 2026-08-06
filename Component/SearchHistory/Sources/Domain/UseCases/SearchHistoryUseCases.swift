import Product

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of what they have searched for before. Those three hold for every
// protocol below, so they are cited once; a comment on any one of them says only what is true of
// that one.

public protocol ClearSearchHistoryUseCase: Sendable {
    @MainActor
    func callAsFunction()
}

public protocol GetSearchHistoryUseCase: Sendable {
    @MainActor
    func callAsFunction() -> SearchHistory
}

public protocol RecordSearchUseCase: Sendable {
    /// Evans, *Domain-Driven Design* (2003), Ch. 5 — Value Objects: takes a `SearchTerm`, so there
    /// is no blank-or-not decision left for a caller to make differently.
    @MainActor
    func callAsFunction(_ term: SearchTerm)
}
