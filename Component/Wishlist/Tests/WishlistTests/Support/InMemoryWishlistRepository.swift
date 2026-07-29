import Combine
import Foundation
import Wishlist

/// A working wishlist repository, not a stub with canned answers: it keeps what it is
/// given and hands it back, so the use cases under test genuinely read, apply and save.
@MainActor
final class InMemoryWishlistRepository: WishlistRepository {
    private let subject: CurrentValueSubject<Wishlist, Never>

    /// Every list handed over, in order, so a test can see whether a use case decided
    /// to save at all.
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
