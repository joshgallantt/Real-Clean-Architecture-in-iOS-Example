import Combine
import Foundation
import Bag
import BagData
import Session

public struct BagDI {
    private let repository: BagRepository

    public let observeBagUseCase: ObserveBagUseCase
    public let bagItemQuantityUseCase: BagItemQuantityUseCase
    public let addProductToBagUseCase: AddProductToBagUseCase
    public let removeProductFromBagUseCase: RemoveProductFromBagUseCase
    public let updateBagItemQuantityUseCase: UpdateBagItemQuantityUseCase

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
        self.bagItemQuantityUseCase = DefaultBagItemQuantityUseCase(repository: repository)
        self.addProductToBagUseCase = DefaultAddProductToBagUseCase(repository: repository)
        self.removeProductFromBagUseCase = DefaultRemoveProductFromBagUseCase(repository: repository)
        self.updateBagItemQuantityUseCase = DefaultUpdateBagItemQuantityUseCase(repository: repository)
    }

    private static func userKey(for session: Session) -> String {
        session.user.map { String($0.id) } ?? "guest"
    }
}
