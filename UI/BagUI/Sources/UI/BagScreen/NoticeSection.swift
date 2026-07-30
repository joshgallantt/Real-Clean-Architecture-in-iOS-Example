import Bag
import Money
import Product

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a section of the bag
/// screen, decided. What it is called, what it says for itself, which symbol and weight of colour it
/// carries, what a shopper can do about a line in it, and the lines themselves.
///
/// Martin, Ch. 8 — Open/Closed Principle: this was five near-identical blocks of view code differing
/// in four constants and one button, and a sixth notice meant editing the view, the presenter's
/// published state, the order things appear in and the test for whether there is any news at all.
/// It is an arm of the table below and a line in `readingOrder` now. The view does not change.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: a section *is* a kind of
/// notice, so it is keyed by `Notice.Kind` rather than by a second enum of the same five things
/// under different names. Screens and domain now break together instead of drifting apart.
struct NoticeSection: Identifiable, Equatable {
    /// What a shopper can do about one line.
    enum Accessory: Equatable {
        /// Nothing worth offering. A price that fell asks nothing of anybody, and something the shop
        /// has stopped selling cannot be waited for or bought — every action this app has is a way
        /// of getting one eventually, so all of them would be promises it cannot keep.
        case nothing

        case tellMeWhenItIsBack

        /// A shopper who agreed to one price and is being asked a higher one needs a way out of it
        /// without hunting the bag for the line again.
        case removeFromBag
    }

    /// Named for what it means rather than which colour it is, so the presenter needs no opinion
    /// about `Color` and the view keeps the one decision that is genuinely its own.
    enum Tint: Equatable {
        case quiet
        case warning
        case good
    }

    /// The order the sections are read in, decided once and here. It runs worst-first: what has gone
    /// for good, then what has gone for now, then what there is not enough of, then what costs more,
    /// and last the one piece of good news.
    static let readingOrder: [Notice.Kind] = [
        .discontinued,
        .outOfStock,
        .onlySomeLeft,
        .priceWentUp,
        .priceWentDown
    ]

    let kind: Notice.Kind
    let title: String
    let description: String
    let icon: String
    let tint: Tint
    let accessory: Accessory
    let rows: [NoticeRow]

    var id: Notice.Kind { kind }

    /// Everything that distinguishes one section from another, in one table. A section cannot be
    /// built with a heading that disagrees with its button, because there is nowhere to say so.
    init(_ kind: Notice.Kind, rows: [NoticeRow]) {
        self.kind = kind
        self.rows = rows

        switch kind {
        case .discontinued:
            title = "No Longer Available"
            description = "Discontinued. Sad - yes, but we thought you should know."
            icon = "xmark.circle"
            tint = .quiet
            accessory = .nothing

        case .outOfStock:
            title = "Out Of Stock"
            description = "Sold out for now, so they've hopped out of your bag. Tap the bell and we'll ping you the moment they're back."
            icon = "shippingbox"
            tint = .warning
            accessory = .tellMeWhenItIsBack

        case .onlySomeLeft:
            title = "Not Enough Left"
            description = "Going fast. We've matched these to whatever's still on the shelf."
            icon = "exclamationmark.triangle"
            tint = .warning
            accessory = .nothing

        case .priceWentUp:
            title = "Price Increases"
            description = "Prices went up on these. Rude, we know. Keep them or take them out — your call."
            icon = "arrow.up.circle"
            tint = .warning
            accessory = .removeFromBag

        case .priceWentDown:
            title = "Price Decreases"
            description = "Good news, these got cheaper. You're welcome — the lower price is already in your total."
            icon = "arrow.down.circle"
            tint = .good
            accessory = .nothing
        }
    }
}

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: one line of a
/// notice, already put into words.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: what a row adds
/// to its heading used to be a pair of optionals that were never both set. Four combinations were
/// representable where three occur, and an out-of-stock row and a discontinued row were the same
/// value with nothing to tell them apart. `Says` has the three states there are.
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
            .howManyLeft(available == 1 ? "Only 1 left" : "Only \(available) left")

        case .priceWentUp(_, let from, let to):
            .priceMoved(PriceMove(was: from.formatted(), now: to.formatted(), isCheaper: false))

        case .priceWentDown(_, let from, let to):
            .priceMoved(PriceMove(was: from.formatted(), now: to.formatted(), isCheaper: true))

        case .outOfStock, .discontinued:
            .nothing
        }
    }
}
