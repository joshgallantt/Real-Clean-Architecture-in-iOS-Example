import Combine
import Foundation
import Testing
import Session
import Wishlist

/// The wishlist is the shopper's, so there has to be a shopper. That rule needs the
/// session, which the list cannot see, so it lives here rather than on the aggregate —
/// and it is the only rule these own.
@MainActor
@Suite("Saving and unsaving products")
struct WishlistUseCaseTests {

    @Test("A signed-in shopper saving something saves a list with it in")
    func savingWhenSignedIn() async {
        let repository = InMemoryWishlistRepository()
        let save = DefaultAddProductToWishlistUseCase(repository: repository, userIsLoggedIn: StubUserIsLoggedIn(true))

        let result = await save(productId: 1)

        #expect(result.isSuccess)
        #expect(repository.wishlist.contains(productId: 1))
    }

    @Test("A guest is asked to sign in, and nothing is saved on their behalf")
    func savingWhenGuest() async {
        let repository = InMemoryWishlistRepository()
        let save = DefaultAddProductToWishlistUseCase(repository: repository, userIsLoggedIn: StubUserIsLoggedIn(false))

        let result = await save(productId: 1)

        #expect(result.failure == .unauthenticated)
        #expect(repository.saved.isEmpty)
    }

    @Test("Saving builds on the list the shopper already has, rather than replacing it")
    func savingReadsBeforeItWrites() async {
        let repository = InMemoryWishlistRepository(Wishlist(items: [WishlistItem(id: 1)]))
        let save = DefaultAddProductToWishlistUseCase(repository: repository, userIsLoggedIn: StubUserIsLoggedIn(true))

        await save(productId: 2)

        #expect(repository.wishlist.count == 2)
    }

    @Test("A signed-in shopper unsaving something saves a list without it")
    func unsaving() async {
        let repository = InMemoryWishlistRepository(Wishlist(items: [WishlistItem(id: 1)]))
        let unsave = DefaultRemoveProductFromWishlistUseCase(repository: repository, userIsLoggedIn: StubUserIsLoggedIn(true))

        await unsave(productId: 1)

        #expect(repository.wishlist.isEmpty)
    }

    @Test("A guest cannot unsave either")
    func unsavingWhenGuest() async {
        let repository = InMemoryWishlistRepository(Wishlist(items: [WishlistItem(id: 1)]))
        let unsave = DefaultRemoveProductFromWishlistUseCase(repository: repository, userIsLoggedIn: StubUserIsLoggedIn(false))

        #expect(await unsave(productId: 1).failure == .unauthenticated)
        #expect(repository.saved.isEmpty)
    }

    @Test("Whether one product is saved ignores the rest of the list moving around it")
    func watchingOneProduct() async {
        let repository = InMemoryWishlistRepository()
        let isSaved = DefaultProductIsWishlistedUseCase(repository: repository)
        let save = DefaultAddProductToWishlistUseCase(repository: repository, userIsLoggedIn: StubUserIsLoggedIn(true))
        var seen: [Bool] = []
        let cancellable = isSaved(productId: 7).sink { seen.append($0) }

        await save(productId: 7)
        await save(productId: 99)
        await save(productId: 7)

        // Saving something else changed the list but not this heart, so the tile
        // showing it is not redrawn.
        #expect(seen == [false, true])
        cancellable.cancel()
    }
}

private extension Result where Success == Void, Failure: Equatable {
    var isSuccess: Bool { if case .success = self { true } else { false } }
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}

private struct StubUserIsLoggedIn: UserIsLoggedInUseCase {
    let loggedIn: Bool

    init(_ loggedIn: Bool) { self.loggedIn = loggedIn }

    func callAsFunction() async -> Bool { loggedIn }
}
