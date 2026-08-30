import Money
import Product
import Home
import ProductTestSupport
@testable import HomeUI

/// The carousels a loaded Home drew, or none at all. A unit test may name the state it expects
/// directly; this is only so the ones about *what was drawn* do not have to unwrap it each time.
extension HomeScreenState {
    var carousels: [HomeCarousel] {
        guard case .loaded(let feed) = self else { return [] }
        return feed.carousels
    }
}
