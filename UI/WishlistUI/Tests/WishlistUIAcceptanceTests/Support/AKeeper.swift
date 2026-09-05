import ProductTestSupport
import SnackbarUITestSupport
import Combine
import Foundation
import Money
import Product
import SnackbarUI
@testable import WishlistUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper has kept and what the shop said about it, never which type held it.
///
/// One driver for both lists on the tab, because there is one list *type*: My Faves and the waitlist
/// differ in where their ids come from and in nothing else. A test written here holds for both,
/// which is the payoff for their being one view model rather than two.
final class AKeeper {
    private let kept = CurrentValueSubject<[ProductID], Never>([])
    let shop = FakeLookUpProductsUseCase()
    let snackbars = SpySnackbarPresenting()

    private(set) lazy var list = SavedProductsViewModel(
        savedProductIds: { [kept] in kept.eraseToAnyPublisher() },
        lookUpProducts: shop,
        snackbar: snackbars,
        couldNotLoad: "Couldn't Load",
        keeping: keeping,
        clear: { [weak self] ids in self?.cleared.append(contentsOf: ids) },
        pageSize: pageSize
    )

    var pageSize = 30

    /// Which of them belong on this list. The tab draws two lists from one set of asks by handing
    /// in opposite answers to this.
    var keeping: (@MainActor (Product) -> Bool)?

    private(set) var cleared: [ProductID] = []

    /// What the shopper is holding — saved, or waiting on. The list only ever sees ids.
    func keeps(_ ids: Int...) {
        kept.send(ids.map(pid))
    }

    func keeps(idsUpTo count: Int) {
        kept.send((1...count).map(pid))
    }

    func stopsKeeping(_ ids: Int...) {
        let dropped = Set(ids.map(pid))
        kept.send(kept.value.filter { !dropped.contains($0) })
    }

    /// Waits for the work the last interaction started, and nothing else.
    ///
    /// It used to yield two hundred times and hope. That is a guess about how
    /// busy the machine is rather than a wait, and it is why a suite fails once
    /// on the run after a rebuild and then passes for a month.
    func settle() async {
        await list.inFlight?.value
    }
}

// MARK: - What the app cannot own

// MARK: - Fixtures
