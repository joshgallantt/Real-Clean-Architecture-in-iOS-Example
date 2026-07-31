import Foundation
import Product
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
public protocol CatchUpOnStockAlertsUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction() async -> Result<Void, StockAlertError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: whether a shopper should be told
/// something is back is a rule, and it takes two answers to decide. The shop's alert service says
/// what has been restocked; the catalog says whether it is still a thing anybody can buy. Only
/// where both agree is the shopper told.
///
/// The second answer is the one worth insisting on. An alert service that is behind, or that is
/// told about a product line the catalog has since dropped, would otherwise have this app announce
/// something a shopper cannot then find — which is a worse failure than saying nothing, because it
/// sends them looking.
///
/// It reaches for `LookUpProductsUseCase` directly, the way `PlaceOrderUseCase` reaches for
/// `GetSessionUseCase` and `BringBagUpToDateUseCase` for the catalog: asking is part of the rule,
/// not something a screen does on its behalf.
public struct DefaultCatchUpOnStockAlertsUseCase: CatchUpOnStockAlertsUseCase {
    private let repository: StockAlertRepository
    private let lookUpProducts: LookUpProductsUseCase
    private let getSession: GetSessionUseCase

    public init(
        repository: StockAlertRepository,
        lookUpProducts: LookUpProductsUseCase,
        getSession: GetSessionUseCase
    ) {
        self.repository = repository
        self.lookUpProducts = lookUpProducts
        self.getSession = getSession
    }

    @MainActor
    @discardableResult
    public func callAsFunction() async -> Result<Void, StockAlertError> {
        guard getSession().isLoggedIn else { return .failure(.unauthenticated) }

        do {
            let restocked = try await repository.whatTheShopSaysIsBack()
            let stillWaitingOn = Set(repository.alerts.waiting.map(\.productId))

            /// Only what this shopper is actually still waiting to hear about. The shop answers
            /// about everything it has been told, and one already acknowledged is not news again.
            let worthChecking = restocked.filter(stillWaitingOn.contains)
            guard !worthChecking.isEmpty else { return .success(()) }

            guard case .success(let products) = await lookUpProducts(ids: worthChecking) else {
                return .failure(.unavailable)
            }

            /// Still sold, and actually on the shelf. A product the catalog has dropped does not
            /// come back at all, and one it describes as out of stock has not come back yet —
            /// whatever the alert service believes.
            let confirmed = Set(products.filter(\.availability.isAvailable).map(\.id))
            guard !confirmed.isEmpty else { return .success(()) }

            try await repository.save(repository.alerts.marking(confirmed, backAt: Date()))
            return .success(())
        } catch {
            return .failure(.unavailable)
        }
    }
}
