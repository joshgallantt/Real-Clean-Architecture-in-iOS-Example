import Foundation
import ProductTestSupport
import Testing
import Product
@testable import ProductActionsUITestSupport
@testable import ProductActionsUI

@MainActor
@Suite("Putting something in the bag")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a shopper in front of a
/// product, driven through the same view models the app builds. Nothing here names a repository or
/// a store.
struct PuttingSomethingInTheBagTests {
    @Test("A shopper taps the bag and it is in their bag, with somewhere to go and see it")
    func addsToBag() async {
        let shown = AProduct()

        shown.bagButton().didTap()

        #expect(shown.bagContains == [pid(1)])
        #expect(shown.snackbarTitles == ["In the Bag"])
    }

    @Test("The count on the button follows what is in the bag")
    func theCountFollows() async {
        let shown = AProduct()
        let button = shown.bagButton()

        button.didTap()
        button.didTap()

        #expect(button.quantity == 2)
    }

    @Test("A bag button can never put in something the shop cannot supply")
    func neverAddsWhatCannotBeSupplied() async {
        let shown = AProduct(.fixture(id: 1, availability: .outOfStock))

        shown.bagButton().didTap()

        #expect(shown.bagContains.isEmpty)
        #expect(shown.snackbarTitles.isEmpty)
    }
}
