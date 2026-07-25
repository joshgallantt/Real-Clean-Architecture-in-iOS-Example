import SwiftUI
import ProductUI

public struct WishlistScreenView: View {
    @ObservedObject var viewModel: WishlistScreenViewModel
    let navigation: WishlistNavigation
    let wishlistButton: (Int) -> AnyView

    public init(
        viewModel: WishlistScreenViewModel,
        navigation: WishlistNavigation,
        wishlistButton: @escaping (Int) -> AnyView
    ) {
        self.viewModel = viewModel
        self.navigation = navigation
        self.wishlistButton = wishlistButton
    }

    public var body: some View {
        ProductGridListView(
            products: viewModel.products,
            isLoadingMore: false,
            onSelect: { navigation.openProductDetails(id: $0.id) },
            onReachEnd: {},
            accessory: { product in wishlistButton(product.id) }
        )
        .overlay {
            if viewModel.products.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Saved Items",
                    systemImage: "heart",
                    description: Text("Tap the heart on a product to save it here.")
                )
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
