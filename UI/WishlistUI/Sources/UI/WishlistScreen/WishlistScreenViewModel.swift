import Combine
import Foundation
import Product
import Wishlist

@MainActor
public final class WishlistScreenViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false

    private let observeWishlist: ObserveWishlistUseCase
    private let getProduct: GetProductUseCase
    private var cancellables = Set<AnyCancellable>()
    private var cache: [Int: Product] = [:]

    public init(observeWishlist: ObserveWishlistUseCase, getProduct: GetProductUseCase) {
        self.observeWishlist = observeWishlist
        self.getProduct = getProduct
    }

    func onAppear() {
        guard cancellables.isEmpty else { return }
        observeWishlist.execute()
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
                if case .success(let product) = await getProduct.execute(id: item.id) {
                    cache[item.id] = product
                }
            }
            isLoading = false
        }
        products = items.compactMap { cache[$0.id] }
    }
}
