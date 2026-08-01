import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("The home screen")
struct HomeScreenViewModelTests {
    private func makeViewModel(
        browseCatalog: StubBrowseCatalog = StubBrowseCatalog(),
        snackbar: SpySnackbarPresenter = SpySnackbarPresenter()
    ) -> HomeScreenViewModel {
        HomeScreenViewModel(browseCatalog: browseCatalog, snackbar: snackbar)
    }

    @Test("Appearing loads the catalog")
    func appearingLoadsTheCatalog() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .success([.fixture(id: 1), .fixture(id: 2)])
        let viewModel = makeViewModel(browseCatalog: browseCatalog)

        await viewModel.onAppear()

        #expect(viewModel.products.map(\.id) == [pid(1), pid(2)])
        #expect(viewModel.isLoading == false)
    }

    @Test("Appearing again once something has already loaded loads nothing more")
    func appearingAgainLoadsNothingMore() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(browseCatalog: browseCatalog)
        await viewModel.onAppear()

        await viewModel.onAppear()

        #expect(browseCatalog.queries.count == 1)
    }

    @Test("A shop that cannot be reached offers to try again, rather than showing nothing said")
    func failureOffersRetry() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .failure(.unavailable)
        let snackbar = SpySnackbarPresenter()
        let viewModel = makeViewModel(browseCatalog: browseCatalog, snackbar: snackbar)

        await viewModel.onAppear()

        #expect(viewModel.products.isEmpty)
        #expect(snackbar.shown.first?.title == "Nothing's Loading")
        #expect(snackbar.shown.first?.action != nil)
    }

    @Test("Retrying asks the shop again, and a second success is shown")
    func retryingAsksAgain() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .failure(.unavailable)
        let snackbar = SpySnackbarPresenter()
        let viewModel = makeViewModel(browseCatalog: browseCatalog, snackbar: snackbar)
        await viewModel.onAppear()
        browseCatalog.result = .success([.fixture(id: 1)])

        snackbar.shown.first?.action?.handler()
        await yieldUntil { browseCatalog.queries.count == 2 }

        #expect(browseCatalog.queries.count == 2)
        #expect(viewModel.products.map(\.id) == [pid(1)])
    }
}
