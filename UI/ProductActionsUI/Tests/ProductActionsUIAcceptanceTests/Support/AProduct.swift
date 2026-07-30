import Combine
import Foundation
import Bag
import Money
import Product
import StockAlert
import AuthUI
import SnackbarUI
@testable import ProductActionsUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. A product in
/// front of a shopper, and the three things they can do to it. Only the two stores and the auth
/// sheet are stood in for — every use case the buttons are handed is the real one.
final class AProduct {
    let product: Product

    private let bagRepository = InMemoryBagRepository()
    private let alertRepository = InMemoryStockAlertRepository()
    private let auth = StubAuthPresenter()
    private let snackbars = RecordingSnackbarPresenter()
    private let navigation = StubNavigation()

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
        auth.answer = true
        alertRepository.signsInOnPrompt = true
    }

    // MARK: - The buttons, built the way the app builds them

    func bagButton() -> BagButtonViewModel {
        BagButtonViewModel(
            product: product,
            observeBagItemQuantity: DefaultObserveBagItemQuantityUseCase(repository: bagRepository),
            addItemToBag: DefaultAddItemToBagUseCase(repository: bagRepository),
            navigation: navigation,
            snackbarPresenter: snackbars
        )
    }

    func stockAlertButton() -> StockAlertButtonViewModel {
        StockAlertButtonViewModel(
            productId: product.id,
            observeWaitingForProduct: DefaultObserveWaitingForProductUseCase(repository: alertRepository),
            askToBeTold: DefaultAskToBeToldWhenBackUseCase(
                repository: alertRepository,
                getSession: alertRepository.session
            ),
            stopBeingTold: DefaultStopBeingToldWhenBackUseCase(
                repository: alertRepository,
                getSession: alertRepository.session
            ),
            authPresenter: auth,
            snackbarPresenter: snackbars
        )
    }

    /// A tap starts a `Task` and returns, exactly as it does on a device. This waits for what the
    /// tap set off to finish before the test asks what the shopper would see.
    func settle() async {
        try? await Task.sleep(for: .milliseconds(50))
    }
}
