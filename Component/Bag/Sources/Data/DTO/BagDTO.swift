import Bag

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object: the serialisation shape, kept out of the
/// domain. It maps at the boundary, so a wire format change stops here.
struct BagDTO: Codable, Sendable {
    let items: [BagItemDTO]
    let notices: [NoticeDTO]

    /// The key on disk stays what it has always been. Renaming a property in Swift is not a reason
    /// for a bag written by an older build to come back empty.
    enum CodingKeys: String, CodingKey {
        case items
        case notices = "pendingChanges"
    }

    init(bag: Bag, notices: Notices) {
        self.items = bag.items.map(BagItemDTO.init(from:))
        self.notices = notices.all.map(NoticeDTO.init(from:))
    }

    func toDomain() -> (bag: Bag, notices: Notices) {
        (
            Bag(items: items.map { $0.toDomain() }),
            Notices(notices.compactMap { $0.toDomain() })
        )
    }
}
