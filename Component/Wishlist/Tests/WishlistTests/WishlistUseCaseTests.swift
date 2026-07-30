import Combine
import Foundation
import Testing
import Session
import Product
import Wishlist

@MainActor
@Suite("Saving and unsaving products")
/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: what the use case sequences, and
/// what it keeps.
struct WishlistUseCaseTests {
    @Test("A signed-in shopper saving something saves a list with it in")
    func savingWhenSignedIn() async {
        let repository = InMemoryWishlistRepository()
        let save = DefaultAddProductToWishlistUseCase(repository: repository, getSession: StubGetSession(signedIn: true))

        let result = await save(productId: pid(1))

        #expect(result.isSuccess)
        #expect(repository.wishlist.contains(productId: pid(1)))
    }

    @Test("A guest is asked to sign in, and nothing is saved on their behalf")
    func savingWhenGuest() async {
        let repository = InMemoryWishlistRepository()
        let save = DefaultAddProductToWishlistUseCase(repository: repository, getSession: StubGetSession(signedIn: false))

        let result = await save(productId: pid(1))

        #expect(result.failure == .unauthenticated)
        #expect(repository.saved.isEmpty)
    }

    @Test("Saving builds on the list the shopper already has, rather than replacing it")
    func savingReadsBeforeItWrites() async {
        let repository = InMemoryWishlistRepository(Wishlist(items: [WishlistItem(productId: pid(1))]))
        let save = DefaultAddProductToWishlistUseCase(repository: repository, getSession: StubGetSession(signedIn: true))

        await save(productId: pid(2))

        #expect(repository.wishlist.itemCount == 2)
    }

    @Test("A signed-in shopper unsaving something saves a list without it")
    func unsaving() async {
        let repository = InMemoryWishlistRepository(Wishlist(items: [WishlistItem(productId: pid(1))]))
        let unsave = DefaultRemoveProductFromWishlistUseCase(repository: repository, getSession: StubGetSession(signedIn: true))

        await unsave(productId: pid(1))

        #expect(repository.wishlist.isEmpty)
    }

    @Test("A guest cannot unsave either")
    func unsavingWhenGuest() async {
        let repository = InMemoryWishlistRepository(Wishlist(items: [WishlistItem(productId: pid(1))]))
        let unsave = DefaultRemoveProductFromWishlistUseCase(repository: repository, getSession: StubGetSession(signedIn: false))

        #expect(await unsave(productId: pid(1)).failure == .unauthenticated)
        #expect(repository.saved.isEmpty)
    }

    @Test("Whether one product is saved ignores the rest of the list moving around it")
    func watchingOneProduct() async {
        let repository = InMemoryWishlistRepository()
        let isSaved = DefaultObserveProductIsWishlistedUseCase(repository: repository)
        let save = DefaultAddProductToWishlistUseCase(repository: repository, getSession: StubGetSession(signedIn: true))
        var seen: [Bool] = []
        let cancellable = isSaved(productId: pid(7)).sink { seen.append($0) }

        await save(productId: pid(7))
        await save(productId: pid(99))
        await save(productId: pid(7))

        #expect(seen == [false, true])
        cancellable.cancel()
    }
}

private extension Result where Success == Void, Failure: Equatable {
    var isSuccess: Bool { if case .success = self { true } else { false } }
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}

private struct StubGetSession: GetSessionUseCase {
    let session: Session

    init(signedIn: Bool) {
        session = signedIn
            ? .authenticated(
                User(
                    id: UserID(rawValue: 42),
                    email: Email("shopper@example.com"),
                    name: PersonName(first: "Ada", last: nil)
                )
              )
            : .guest
    }

    @MainActor
    func callAsFunction() -> Session { session }
}
