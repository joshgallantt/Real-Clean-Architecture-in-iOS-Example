/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: the feature
/// declares the moves it needs; the app layer conforms. Nothing here learns what a destination is
/// or which tab it sits in.
///
/// Fowler, *PoEAA* (2002) — Separated Interface. Martin, Ch. 10 — Interface Segregation Principle:
/// the product actions make exactly one move between them — the "View" on an added-to-bag notice —
/// so that is the whole protocol. Importing `BagNavigation` for it would make every package that
/// renders a heart depend on the bag feature.
public protocol ProductActionsNavigation: AnyObject {
    func switchToBagTab()
}
