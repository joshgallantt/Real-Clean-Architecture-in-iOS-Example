import ProductTestSupport
import SnackbarUITestSupport
import Foundation
import Tracking
import TrackingTestSupport
import Product
import StockAlert
import StockAlertTestSupport
@testable import StockAlertUI
@testable import StockAlertUITestSupport

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper asked to be told about and what the shop said about it, never which type held it.
///
/// The real use cases over alerts kept in memory, so the list a test reads is the one the domain
/// would answer with. Only the shop and the clearing of an alert are stood in for.
final class AWaiter {
    private let repository = FakeStockAlertRepository()
    private let clearing = SpySetProductStockAlertUseCase()
    let shop = FakeLookUpProductsUseCase()
    let snackbars = SpySnackbarPresenting()

    private(set) lazy var list = StockAlertProductsViewModel(
        getStockAlertProducts: DefaultGetStockAlertProductsUseCase(repository: repository, lookUpProducts: shop),
        observeStockAlerts: DefaultObserveStockAlertsUseCase(repository: repository),
        setProductStockAlert: clearing,
        navigation: SpyStockAlertNavigation(),
        snackbar: snackbars,
        trackScreenView: SpyTrackScreenViewUseCase(),
        trackElementView: SpyTrackElementViewUseCase(),
        trackElementInteraction: SpyTrackElementInteractionUseCase()
    )

    /// The alerts Clear asked to have turned off.
    var cleared: [ProductID] {
        clearing.calls.filter { !$0.isOn }.map(\.productId)
    }

    /// What the shopper has asked to be told about.
    func asksAbout(_ ids: Int...) async throws {
        try await repository.save(StockAlerts(items: ids.map { StockAlert(productId: pid($0)) }))
    }

    /// Waits for the work the last interaction started, and nothing else.
    func settle() async {
        await list.inFlight?.value
    }
}
