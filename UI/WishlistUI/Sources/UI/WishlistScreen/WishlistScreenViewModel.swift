import Combine
import Foundation
import Product
import Session
import Wishlist

@MainActor
public final class WishlistScreenViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isAuthenticated = false

    private let observeWishlist: ObserveWishlistUseCase
    private let getProduct: GetProductUseCase
    private let observeSession: ObserveSessionUseCase
    private var cancellables = Set<AnyCancellable>()
    private var cache: [Int: Product] = [:]

    public init(
        observeWishlist: ObserveWishlistUseCase,
        getProduct: GetProductUseCase,
        observeSession: ObserveSessionUseCase
    ) {
        self.observeWishlist = observeWishlist
        self.getProduct = getProduct
        self.observeSession = observeSession
    }

    func onAppear() {
        guard cancellables.isEmpty else { return }

        observeSession()
            .sink { [weak self] session in
                self?.isAuthenticated = session.isLoggedIn
            }
            .store(in: &cancellables)

        observeWishlist()
            .sink { [weak self] items in
                Task { await self?.refresh(items) }
            }
            .store(in: &cancellables)
    }

    private func refresh(_ items: [WishlistItem]) async {
        let missing = items.filter { cache[$0.id] == nil }
        if !missing.isEmpty {
            isLoading = true
            for item in missing {
                if case .success(let product) = await getProduct(id: item.id) {
                    cache[item.id] = product
                }
            }
            isLoading = false
        }
        products = items.compactMap { cache[$0.id] }
    }
}
