import Foundation
import Testing
import Product
@testable import WishlistUI

@MainActor
@Suite("A list of saved ids, filled in from the catalog")
struct SavedProductsViewModelTests {
    private func makeViewModel(
        savedProductIds: StubObserveSavedProductIds = StubObserveSavedProductIds(),
        lookUpProducts: StubLookUpProducts = StubLookUpProducts(),
        snackbar: SpySnackbarPresenter = SpySnackbarPresenter(),
        couldNotLoad: String = "Couldn't Load",
        keeping: (@MainActor (Product) -> Bool)? = nil,
        clear: SpyClearTheList = SpyClearTheList(),
        pageSize: Int = 30
    ) -> SavedProductsViewModel {
        SavedProductsViewModel(
            savedProductIds: savedProductIds.callAsFunction,
            lookUpProducts: lookUpProducts,
            snackbar: snackbar,
            couldNotLoad: couldNotLoad,
            keeping: keeping,
            clear: clear.callAsFunction,
            pageSize: pageSize
        )
    }

    @Test("What a shopper is holding is filled in from the catalog")
    func showsWhatIsHeldFilledIn() async {
        let savedProductIds = StubObserveSavedProductIds([pid(1), pid(2)])
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success([.fixture(id: 1), .fixture(id: 2)])
        let viewModel = makeViewModel(savedProductIds: savedProductIds, lookUpProducts: lookUpProducts)

        viewModel.onAppear()
        await settle()

        #expect(viewModel.products.map(\.id) == [pid(1), pid(2)])
        #expect(viewModel.savedCount == 2)
    }

    @Test("Holding nothing asks the shop nothing")
    func holdingNothingAsksNothing() async {
        let lookUpProducts = StubLookUpProducts()
        let viewModel = makeViewModel(lookUpProducts: lookUpProducts)

        viewModel.onAppear()
        await settle()

        #expect(viewModel.isEmpty)
        #expect(lookUpProducts.asked.isEmpty)
    }

    @Test("Something the shop no longer answers about is not shown")
    func discontinuedIsNotShown() async {
        let savedProductIds = StubObserveSavedProductIds([pid(1), pid(2)])
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(savedProductIds: savedProductIds, lookUpProducts: lookUpProducts)

        viewModel.onAppear()
        await settle()

        #expect(viewModel.products.map(\.id) == [pid(1)])
    }

    @Test("The count is what the shopper holds, not what fits on screen")
    func countIsOfEverythingHeldNotJustShown() async {
        let savedProductIds = StubObserveSavedProductIds((1...5).map(pid))
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success((1...2).map { .fixture(id: $0) })
        let viewModel = makeViewModel(savedProductIds: savedProductIds, lookUpProducts: lookUpProducts, pageSize: 2)

        viewModel.onAppear()
        await settle()

        #expect(viewModel.products.count == 2)
        #expect(viewModel.savedCount == 5)
    }

    @Test("Reaching the end of the list asks for the next page")
    func reachingTheEndAsksForTheNextPage() async {
        let savedProductIds = StubObserveSavedProductIds((1...5).map(pid))
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success((1...5).map { .fixture(id: $0) })
        let viewModel = makeViewModel(savedProductIds: savedProductIds, lookUpProducts: lookUpProducts, pageSize: 2)
        viewModel.onAppear()
        await settle()

        viewModel.onReachEnd()
        await settle()

        #expect(viewModel.products.count == 4)
    }

    @Test("A dropped connection leaves the list exactly as it was")
    func aDroppedConnectionLeavesTheListAsItWas() async {
        let savedProductIds = StubObserveSavedProductIds([pid(1)])
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(savedProductIds: savedProductIds, lookUpProducts: lookUpProducts)
        viewModel.onAppear()
        await settle()

        savedProductIds.send([pid(1), pid(2)])
        lookUpProducts.result = .failure(.unavailable)
        await settle()

        #expect(viewModel.products.map(\.id) == [pid(1)])
        #expect(viewModel.isEmpty == false)
    }

    @Test("A dropped connection is reported with the title this list was given")
    func aDroppedConnectionIsReportedWithItsOwnTitle() async {
        let savedProductIds = StubObserveSavedProductIds([pid(1)])
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .failure(.unavailable)
        let snackbar = SpySnackbarPresenter()
        let viewModel = makeViewModel(
            savedProductIds: savedProductIds,
            lookUpProducts: lookUpProducts,
            snackbar: snackbar,
            couldNotLoad: "Couldn't Load My Faves"
        )

        viewModel.onAppear()
        await settle()

        #expect(snackbar.shown.first?.title == "Couldn't Load My Faves")
    }

    @Test("A filtered list shows only what it is told to keep")
    func aFilteredListShowsOnlyWhatItKeeps() async {
        let savedProductIds = StubObserveSavedProductIds([pid(1), pid(2)])
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success([
            .fixture(id: 1, availability: .outOfStock),
            .fixture(id: 2)
        ])
        let viewModel = makeViewModel(
            savedProductIds: savedProductIds,
            lookUpProducts: lookUpProducts,
            keeping: { !$0.availability.isAvailable }
        )

        viewModel.onAppear()
        await settle()

        #expect(viewModel.products.map(\.id) == [pid(1)])
    }

    @Test("A filtered list is counted by what it shows, not by what was asked")
    func aFilteredListIsCountedByWhatItShows() async {
        let savedProductIds = StubObserveSavedProductIds([pid(1), pid(2)])
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success([
            .fixture(id: 1, availability: .outOfStock),
            .fixture(id: 2)
        ])
        let viewModel = makeViewModel(
            savedProductIds: savedProductIds,
            lookUpProducts: lookUpProducts,
            keeping: { !$0.availability.isAvailable }
        )

        viewModel.onAppear()
        await settle()

        #expect(viewModel.savedCount == 1)
    }

    @Test("Clearing takes away everything currently on the list")
    func clearingTakesEverythingOnTheList() async {
        let savedProductIds = StubObserveSavedProductIds([pid(1), pid(2)])
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success([.fixture(id: 1), .fixture(id: 2)])
        let clear = SpyClearTheList()
        let viewModel = makeViewModel(savedProductIds: savedProductIds, lookUpProducts: lookUpProducts, clear: clear)
        viewModel.onAppear()
        await settle()

        viewModel.didConfirmClear()
        await settle()

        #expect(clear.calls == [[pid(1), pid(2)]])
    }

    @Test("Clearing an empty list asks nothing of anybody")
    func clearingAnEmptyListAsksNothing() async {
        let clear = SpyClearTheList()
        let viewModel = makeViewModel(clear: clear)
        viewModel.onAppear()
        await settle()

        viewModel.didConfirmClear()
        await settle()

        #expect(clear.calls.isEmpty)
    }

    @Test("Something already filled in is not asked about again")
    func doesNotReaskForWhatItHas() async {
        let savedProductIds = StubObserveSavedProductIds([pid(1)])
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(savedProductIds: savedProductIds, lookUpProducts: lookUpProducts)
        viewModel.onAppear()
        await settle()

        savedProductIds.send([pid(1), pid(2)])
        lookUpProducts.result = .success([.fixture(id: 2)])
        await settle()

        #expect(lookUpProducts.asked == [[pid(1)], [pid(2)]])
    }

    @Test("Appearing again does not subscribe a second time")
    func appearingAgainDoesNotResubscribe() async {
        let savedProductIds = StubObserveSavedProductIds([pid(1)])
        let lookUpProducts = StubLookUpProducts()
        lookUpProducts.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(savedProductIds: savedProductIds, lookUpProducts: lookUpProducts)
        viewModel.onAppear()
        await settle()

        viewModel.onAppear()
        lookUpProducts.result = .success([.fixture(id: 2)])
        savedProductIds.send([pid(1), pid(2)])
        await settle()

        #expect(lookUpProducts.asked == [[pid(1)], [pid(2)]])
    }
}
