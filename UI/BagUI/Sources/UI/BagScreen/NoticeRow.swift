import Bag
import Product

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: one line of a
/// notice, already put into words.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: what a row adds
/// to its heading used to be a pair of optionals that were never both set. Four combinations were
/// representable where three occur. `Says` has the three states there are.
struct NoticeRow: Identifiable, Equatable {
    /// Two amounts and a direction rather than a finished sentence. A price move is worth seeing
    /// rather than reading — the old struck through, the new one coloured by which way it went — and
    /// a view cannot strike through half of a sentence. The words come from here, the emphasis from
    /// the view, and that is the line between the two rather than a leak across it.
    struct PriceMove: Equatable {
        let was: String
        let now: String
        let isCheaper: Bool
    }

    /// What a line has to add to what its heading already said. Most have nothing: that a thing is
    /// out of stock is what its section is for, and saying it again down the column is a sentence to
    /// read past on every line to reach the product, which is the part that differs.
    enum Says: Equatable {
        case nothing
        case howManyLeft(String)
        case priceMoved(PriceMove)
    }

    let id: ProductID
    let name: String?
    let imageURL: String?
    let says: Says

    init(notice: Notice, name: String?, imageURL: String?) {
        self.id = notice.productId
        self.name = name
        self.imageURL = imageURL
        self.says = Self.says(about: notice)
    }

    private static func says(about notice: Notice) -> Says {
        switch notice {
        case .onlySomeLeft(_, let available):
            .howManyLeft(available == 1 ? "Last one" : "\(available) left")

        case .priceWentUp(_, let from, let to):
            .priceMoved(PriceMove(was: from.formatted(), now: to.formatted(), isCheaper: false))

        case .priceWentDown(_, let from, let to):
            .priceMoved(PriceMove(was: from.formatted(), now: to.formatted(), isCheaper: true))

        case .outOfStock:
            .nothing
        }
    }
}
