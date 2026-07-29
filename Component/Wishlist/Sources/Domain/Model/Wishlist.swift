import Foundation

/// The products a shopper has saved to come back to.
///
/// A wishlist holds ids and the day each was saved, and nothing else. Unlike a bag it
/// has no prices of its own — a shopper saves something precisely to watch what happens
/// to it — so what each entry is called and costs is the catalog's to answer, freshly,
/// every time.
///
/// Everything inside changes through here: saving something twice, or removing
/// something that was never saved, are questions about the list and are answered by it.
public struct Wishlist: Equatable, Sendable {
    public let items: [WishlistItem]

    /// Newest first is the list's own order, so it is established here rather than
    /// trusted from whatever handed the entries over.
    public init(items: [WishlistItem] = []) {
        self.items = items.sorted { $0.dateAdded > $1.dateAdded }
    }

    public var isEmpty: Bool { items.isEmpty }

    public var count: Int { items.count }

    public func contains(productId: Int) -> Bool {
        items.contains { $0.id == productId }
    }

    /// Saving something already saved changes nothing, and in particular does not move
    /// it to the top: the shopper saved it when they saved it.
    public func adding(_ item: WishlistItem) -> Wishlist {
        guard !contains(productId: item.id) else { return self }
        return Wishlist(items: items + [item])
    }

    public func removing(productId: Int) -> Wishlist {
        guard contains(productId: productId) else { return self }
        return Wishlist(items: items.filter { $0.id != productId })
    }
}
