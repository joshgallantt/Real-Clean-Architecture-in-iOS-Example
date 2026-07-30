import Combine
import Foundation
import Product
import Wishlist

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a working repository rather
/// than a stub with canned answers, so the use cases under test genuinely read, apply and save.
///
/// Fowler, *PoEAA* (2002) — Repository.
final class InMemoryWishlistRepository: WishlistRepository {
    private let subject: CurrentValueSubject<Wishlist, Never>

    private(set) var saved: [Wishlist] = []

    init(_ wishlist: Wishlist = Wishlist()) {
        self.subject = CurrentValueSubject(wishlist)
    }

    var wishlist: Wishlist { subject.value }

    var wishlistPublisher: AnyPublisher<Wishlist, Never> { subject.eraseToAnyPublisher() }

    func save(_ wishlist: Wishlist) {
        saved.append(wishlist)
        subject.value = wishlist
    }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}
