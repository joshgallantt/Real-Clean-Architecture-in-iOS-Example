import Bag
import Product

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: one thing that
/// changed since the shopper last viewed their bag, already put into words.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: what a row says
/// is one of three things and never two, so it is a case rather than a set of optionals.
struct BagChangeRow: Identifiable, Equatable {
    /// Two amounts and a direction rather than a finished sentence. A price move is worth seeing
    /// rather than reading — the old struck through, the new one coloured by which way it went — and
    /// a view cannot strike through half of a sentence. The words come from here, the emphasis from
    /// the view, and that is the line between the two rather than a leak across it.
    struct PriceMove: Equatable {
        let was: String
        let now: String
        let isCheaper: Bool
    }

    enum Says: Equatable {
        /// Told apart from a shortage because it is the one change a shopper can wait out, so it is
        /// the one row that carries a bell.
        case soldOut(String)
        case howManyLeft(String)
        case priceMoved(PriceMove)
    }

    /// The change itself. A product whose price moved and whose line was cut has two rows, and this
    /// is what tells them apart.
    let id: BagChange

    /// The product the change is about, once the shop has said what it is. See `BagRow`.
    let product: Product?
    let says: Says

    init(change: BagChange, product: Product?) {
        self.id = change
        self.product = product

        switch change {
        case .soldOut:
            says = .soldOut("Sold out")

        case .onlySomeLeft(_, let available):
            says = .howManyLeft(available == 1 ? "Only 1 left" : "Only \(available) left")

        case .priceWentUp(_, let from, let to):
            says = .priceMoved(PriceMove(was: from.formatted(), now: to.formatted(), isCheaper: false))

        case .priceWentDown(_, let from, let to):
            says = .priceMoved(PriceMove(was: from.formatted(), now: to.formatted(), isCheaper: true))
        }
    }
}
