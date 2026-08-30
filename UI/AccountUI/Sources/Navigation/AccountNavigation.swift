/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle:
/// what this screen can ask for, not who answers.
///
/// It used to be handed its rows already built, as two `AnyView`s from the
/// composition root, on the grounds that the package should not learn there is
/// an order domain. It does not learn that from this either — an account can
/// show somebody their orders without knowing what an order is.
///
/// What the old shape actually moved was the rendering: the label and the icon
/// were decided in the composition root, while this package still wrote the
/// `Section` around them. A screen half-drawn in two places is drawn in neither,
/// and no test could say that tapping the row went anywhere, because the row was
/// opaque to the suite as well as to the screen.
public protocol AccountNavigation: AnyObject {
    func openOrderHistory()
    func openSettings()
}
