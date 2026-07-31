import SwiftUI
import Product
import ProductUI
import AuthUI

public struct WishlistScreenView: View {
    @ObservedObject var viewModel: WishlistScreenViewModel
    let navigation: WishlistNavigation
    let wishlistButton: (ProductID) -> AnyView
    let bagButton: (Product) -> AnyView
    let authPresenter: AuthPresenting

    public init(
        viewModel: WishlistScreenViewModel,
        navigation: WishlistNavigation,
        wishlistButton: @escaping (ProductID) -> AnyView,
        bagButton: @escaping (Product) -> AnyView,
        authPresenter: AuthPresenting
    ) {
        self.viewModel = viewModel
        self.navigation = navigation
        self.wishlistButton = wishlistButton
        self.bagButton = bagButton
        self.authPresenter = authPresenter
    }

    public var body: some View {
        Group {
            if viewModel.isAuthenticated {
                savedProducts
            } else {
                guestPrompt
            }
        }
        .task {
            viewModel.onAppear()
        }
    }

    /// One notice for all of them, and no rows. The wishlist found out these had gone by being
    /// told nothing about them, so it has no name and no picture for any — a list of grey
    /// placeholders would say less than the sentence does.
    private var discontinuedNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle")
                .foregroundStyle(.secondary)
            Text("One or more of your wishlist items has been discontinued. Sad, yes. But we thought you should know.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var savedProducts: some View {
        ProductGridListView(
            products: viewModel.products,
            isLoadingMore: viewModel.isLoadingMore,
            onSelect: { navigation.openProductDetails(product: $0) },
            onReachEnd: { viewModel.onReachEnd() },
            accessory: { product in wishlistButton(product.id) },
            leadingAccessory: { product in bagButton(product) }
        )
        /// Above the grid rather than in it, because it is about the list and not about any one
        /// thing on it — and because the things it is about are precisely the ones not there.
        .safeAreaInset(edge: .top) {
            if viewModel.somethingHasBeenDiscontinued {
                discontinuedNotice
            }
        }
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
                Task {
                    await authPresenter.show(AuthenticationPrompt(
                        title: "Save Your Favourites",
                        message: "Log in or create an account to build your wishlist.",
                        icon: "heart.fill"
                    ))
                }
            } label: {
                Text("Log In or Create Account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
