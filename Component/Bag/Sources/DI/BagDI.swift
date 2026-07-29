import Combine
import Foundation
import Bag
import BagData
import Session

public struct BagDI {
    private let repository: BagRepository

    public let observeBagUseCase: ObserveBagUseCase
    public let observeBagChangesUseCase: ObserveBagChangesUseCase
    public let bagItemQuantityUseCase: BagItemQuantityUseCase
    public let addItemToBagUseCase: AddItemToBagUseCase
    public let setBagItemQuantityUseCase: SetBagItemQuantityUseCase
    public let reconcileBagUseCase: ReconcileBagUseCase
    public let acknowledgeBagChangeUseCase: AcknowledgeBagChangeUseCase

    @MainActor
    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        store: BagStore = FileBagStore()
    ) {
        let repository = DefaultBagRepository(
            store: store,
            userKey: Self.userKey(for: getSession()),
            userKeyPublisher: observeSession().map(Self.userKey(for:)).eraseToAnyPublisher()
        )
        self.repository = repository

        self.observeBagUseCase = DefaultObserveBagUseCase(repository: repository)
        self.observeBagChangesUseCase = DefaultObserveBagChangesUseCase(repository: repository)
        self.bagItemQuantityUseCase = DefaultBagItemQuantityUseCase(repository: repository)
        self.addItemToBagUseCase = DefaultAddItemToBagUseCase(repository: repository)
        self.setBagItemQuantityUseCase = DefaultSetBagItemQuantityUseCase(repository: repository)
        self.reconcileBagUseCase = DefaultReconcileBagUseCase(repository: repository)
        self.acknowledgeBagChangeUseCase = DefaultAcknowledgeBagChangeUseCase(repository: repository)
    }

    private static func userKey(for session: Session) -> String {
        session.user.map { String($0.id) } ?? "guest"
    }
}
