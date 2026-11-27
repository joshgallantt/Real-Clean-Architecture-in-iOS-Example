import Bag

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object: the serialisation shape, kept out of the
/// domain. It maps at the boundary, so a wire format change stops here.
///
/// A bag written by an older build also holds a list of what the shop had changed, under
/// `pendingChanges`. That is worked out afresh now rather than kept, so the key is not named here
/// and whatever is under it is not read: the lines beside it load as they always did.
struct BagDTO: Codable, Sendable {
    let items: [BagItemDTO]

    init(bag: Bag) {
        self.items = bag.items.map(BagItemDTO.init(from:))
    }

    func toDomain() -> Bag {
        Bag(items: items.map { $0.toDomain() })
    }
}
