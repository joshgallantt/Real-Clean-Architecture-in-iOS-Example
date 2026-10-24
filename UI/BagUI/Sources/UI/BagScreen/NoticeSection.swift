import Bag

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
    /// for now, then what there is not enough of, then what costs more, and last the one piece of
    /// good news.
    static let readingOrder: [Notice.Kind] = [
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
        case .outOfStock:
            title = "Sold Out"
            description = "Gone for now, so they're out of your bag. Hit the bell and we'll tell you the second they're back."
            icon = "shippingbox"
            tint = .warning
            accessory = .tellMeWhenItIsBack

        case .onlySomeLeft:
            title = "Nearly Gone"
            description = "Going fast. We've dropped you to what's actually left."
            icon = "exclamationmark.triangle"
            tint = .warning
            accessory = .nothing

        case .priceWentUp:
            title = "Went Up"
            description = "These got more expensive. Rude. Keep them or lose them — up to you."
            icon = "arrow.up.circle"
            tint = .warning
            accessory = .removeFromBag

        case .priceWentDown:
            title = "Went Down"
            description = "These got cheaper. You're welcome. The new price is already in your total."
            icon = "arrow.down.circle"
            tint = .good
            accessory = .nothing
        }
    }
}
