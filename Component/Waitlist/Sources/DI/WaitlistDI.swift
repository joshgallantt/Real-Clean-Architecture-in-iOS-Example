import Combine
import Foundation
import Product
import Session
import Waitlist
import WaitlistData

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. It
/// is the only thing that knows the concrete types, so it is the only thing that has to change when
/// one is swapped. Not unit tested — there is no behaviour here to test.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection.
public struct WaitlistDI {
    private let repository: WaitlistRepository

    public let observeWaitlistUseCase: ObserveWaitlistUseCase
    public let observeProductIsWaitlistedUseCase: ObserveProductIsWaitlistedUseCase
    public let setProductIsWaitlistedUseCase: SetProductIsWaitlistedUseCase
    public let getStillSoldOutProductsUseCase: GetStillSoldOutProductsUseCase
    public let getBackInStockProductsUseCase: GetBackInStockProductsUseCase

    @MainActor
    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        lookUpProducts: LookUpProductsUseCase,
        store: WaitlistStore = FileWaitlistStore()
    ) {
        /// Evans, *Domain-Driven Design* (2003) — Bounded Context: turning a session into an owner
        /// happens here, once.
        let repository = DefaultWaitlistRepository(
            store: store,
            owner: Self.owner(for: getSession()),
            ownerPublisher: observeSession()
                .map(Self.owner(for:))
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
        self.repository = repository

        self.observeWaitlistUseCase = DefaultObserveWaitlistUseCase(repository: repository)
        self.observeProductIsWaitlistedUseCase = DefaultObserveProductIsWaitlistedUseCase(repository: repository)
        self.setProductIsWaitlistedUseCase = DefaultSetProductIsWaitlistedUseCase(
            repository: repository,
            getSession: getSession
        )
        self.getStillSoldOutProductsUseCase = DefaultGetStillSoldOutProductsUseCase(
            repository: repository,
            lookUpProducts: lookUpProducts
        )
        self.getBackInStockProductsUseCase = DefaultGetBackInStockProductsUseCase(
            repository: repository,
            lookUpProducts: lookUpProducts
        )
    }

    /// Evans, *Domain-Driven Design* (2003) — Assertions: exhaustive over `Session`. `nil` is the
    /// absence of anywhere to send a message, not a guest with an empty list — a guest has given
    /// nobody an address to tell.
    private static func owner(for session: Session) -> UserID? {
        switch session {
        case .guest:
            nil
        case .authenticated(let user):
            user.id
        }
    }
}
