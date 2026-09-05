import AuthUITestSupport
import BagTestSupport
import Combine
import Foundation
import Bag
import Money
import Product
import ProductTestSupport
import StockAlert
import AuthUI
import SnackbarUI
import SnackbarUITestSupport
import StockAlertTestSupport
@testable import ProductActionsUITestSupport
@testable import ProductActionsUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. A product in
/// front of a shopper, and the three things they can do to it. Only the two stores and the auth
/// sheet are stood in for — every use case the buttons are handed is the real one.
final class AProduct {
    let product: Product

    private let bagRepository = FakeBagRepository()
    private let alertRepository = FakeStockAlertRepository()
    private let auth = SpyAuthPresenting()
    private let snackbars = SpySnackbarPresenting()
    private let navigation = SpyProductActionsNavigation()

    init(_ product: Product = .fixture(id: 1), signedIn: Bool = true) {
        self.product = product
        alertRepository.isSignedIn = signedIn
    }

    // MARK: - What the shopper sees

    var snackbarTitles: [String] { snackbars.shown.map(\.title) }
    var bagContains: [ProductID] { bagRepository.bag.items.map(\.id) }
    var waitingFor: [ProductID] { alertRepository.alerts.alerts.map(\.productId) }
    var wasAskedToSignIn: Bool { auth.wasAsked }

    /// The shopper signs in when the sheet asks them to, rather than dismissing it.
    func willSignInWhenAsked() {
        auth.signsIn = true
        alertRepository.signsInOnPrompt = true
    }

    // MARK: - The buttons, built the way the app builds them

    /// Built and appeared, the way the app does both: the button subscribes when
    /// it comes on screen rather than when it is constructed.
    func bagButton() -> BagButtonViewModel {
        let button = BagButtonViewModel(
            product: product,
            observeBagItemQuantity: DefaultObserveBagItemQuantityUseCase(repository: bagRepository),
            addItemToBag: DefaultAddItemToBagUseCase(repository: bagRepository),
            navigation: navigation,
            snackbarPresenter: snackbars
        )
        button.onAppear()
        return button
    }

    func stockAlertButton() -> StockAlertButtonViewModel {
        let button = StockAlertButtonViewModel(
            productId: product.id,
            observeWaitlistStatus: DefaultObserveWaitlistStatusUseCase(repository: alertRepository),
            setStockAlert: DefaultSetStockAlertForProductUseCase(
                repository: alertRepository,
                getSession: alertRepository.session
            ),
            authPresenter: auth,
            snackbarPresenter: snackbars
        )
        button.onAppear()
        return button
    }

}
