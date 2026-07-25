import SwiftUI
import ProductUI
import LoginUI

public struct WishlistScreenView: View {
    @ObservedObject var viewModel: WishlistScreenViewModel
    let navigation: WishlistNavigation
    let wishlistButton: (Int) -> AnyView
    let authPresenting: AuthPresenting

    public init(
        viewModel: WishlistScreenViewModel,
        navigation: WishlistNavigation,
        wishlistButton: @escaping (Int) -> AnyView,
        authPresenting: AuthPresenting
    ) {
        self.viewModel = viewModel
        self.navigation = navigation
        self.wishlistButton = wishlistButton
        self.authPresenting = authPresenting
    }

    public var body: some View {
        Group {
            if viewModel.isAuthenticated {
                savedProducts
            } else {
                guestPrompt
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var savedProducts: some View {
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
    }

    private var guestPrompt: some View {
        ContentUnavailableView {
            Label("Save Your Favourites", systemImage: "heart")
        } description: {
            Text("Log in or create an account to build your wishlist.")
        } actions: {
            Button {
                Task { await authPresenting.requireAuthentication() }
            } label: {
                Text("Log In or Create Account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
