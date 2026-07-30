import Foundation
import Product

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

    /// Each product appears once, and newest first is the list's own order — both
    /// established here rather than trusted from whatever handed the entries over.
    public init(items: [WishlistItem] = []) {
        var seen: Set<ProductID> = []
        self.items = items
            .filter { seen.insert($0.productId).inserted }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    public var isEmpty: Bool { items.isEmpty }

    public var itemCount: Int { items.count }

    public func contains(productId: ProductID) -> Bool {
        items.contains { $0.productId == productId }
    }

    /// Saving something already saved changes nothing, and in particular does not move
    /// it to the top: the shopper saved it when they saved it.
    public func adding(_ item: WishlistItem) -> Wishlist {
        guard !contains(productId: item.productId) else { return self }
        return Wishlist(items: items + [item])
    }

    public func removing(productId: ProductID) -> Wishlist {
        guard contains(productId: productId) else { return self }
        return Wishlist(items: items.filter { $0.productId != productId })
    }
}
