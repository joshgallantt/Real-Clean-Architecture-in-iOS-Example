import SwiftUI
import Product
import ProductUI
import AuthUI

/// The tab a shopper keeps an eye on things from. Two lists, because they are two different kinds
/// of interest: what they have chosen to remember, and what they are waiting on the shop for. Each
/// shows a handful and offers the rest.
public struct WishlistScreenView: View {
    @ObservedObject var session: WishlistScreenViewModel
    @ObservedObject var faves: SavedProductsViewModel
    @ObservedObject var notifyMe: SavedProductsViewModel
    @ObservedObject var backInStock: SavedProductsViewModel

    let navigation: WishlistNavigation
    let wishlistButton: (ProductID) -> AnyView
    let bagButton: (Product) -> AnyView
    let authPresenter: AuthPresenting

    public init(
        session: WishlistScreenViewModel,
        faves: SavedProductsViewModel,
        notifyMe: SavedProductsViewModel,
        backInStock: SavedProductsViewModel,
        navigation: WishlistNavigation,
        wishlistButton: @escaping (ProductID) -> AnyView,
        bagButton: @escaping (Product) -> AnyView,
        authPresenter: AuthPresenting
    ) {
        self.session = session
        self.faves = faves
        self.notifyMe = notifyMe
        self.backInStock = backInStock
        self.navigation = navigation
        self.wishlistButton = wishlistButton
        self.bagButton = bagButton
        self.authPresenter = authPresenter
    }

    public var body: some View {
        Group {
            if session.isAuthenticated {
                lists
            } else {
                guestPrompt
            }
        }
        .task {
            faves.onAppear()
            notifyMe.onAppear()
            backInStock.onAppear()
            await session.onAppear()
        }
    }

    private var lists: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                /// A section of its own at the top, the way the bag does it, rather than something
                /// pinned above the scroll view. Inset over the top of a navigation title, it
                /// fought with the title on every scroll — and a notice that jitters reads as a
                /// glitch rather than as news.
                if somethingHasBeenDiscontinued {
                    discontinuedNotice
                }

                /// First, and only when there is something in it. This is the promise the bell made,
                /// kept — a shopper who opens this tab to find something they were waiting for has
                /// had the app do the one thing it said it would.
                if !backInStock.isEmpty {
                    SavedProductsCarousel(
                        viewModel: backInStock,
                        title: "Back in Stock",
                        icon: "sparkles",
                        tint: .green,
                        description: "You asked to be told — here they are. Add them before they go again.",
                        emptyMessage: "",
                        onSelect: { navigation.openProductDetails(product: $0) },
                        onViewAll: { navigation.openAllNotifyMe() },
                        accessory: { product in AnyView(wishlistButton(product.id)) },
                        leadingAccessory: { product in AnyView(bagButton(product)) }
                    )
                }

                SavedProductsCarousel(
                    viewModel: notifyMe,
                    title: "Notify Me",
                    icon: "bell.fill",
                    tint: .orange,
                    description: "Sold out, but coming back. We'll ping you the moment they are.",
                    emptyMessage: "Tap the bell on anything that's sold out and it'll wait here.",
                    onSelect: { navigation.openProductDetails(product: $0) },
                    onViewAll: { navigation.openAllNotifyMe() },
                    accessory: { product in AnyView(wishlistButton(product.id)) },
                    leadingAccessory: { product in AnyView(bagButton(product)) }
                )

                SavedProductsCarousel(
                    viewModel: faves,
                    title: "My Faves",
                    icon: "heart.fill",
                    tint: .accentColor,
                    description: "Everything you've saved, ready when you are.",
                    emptyMessage: "Tap the heart on a product to save it here.",
                    onSelect: { navigation.openProductDetails(product: $0) },
                    onViewAll: { navigation.openAllFaves() },
                    accessory: { product in AnyView(wishlistButton(product.id)) },
                    leadingAccessory: { product in AnyView(bagButton(product)) }
                )
            }
            .padding(.vertical)
        }
    }

    /// Either list may lose something, and a shopper reads one sentence about their saved things
    /// rather than the same sentence twice under two headings.
    private var somethingHasBeenDiscontinued: Bool {
        faves.somethingHasBeenDiscontinued || notifyMe.somethingHasBeenDiscontinued
    }

    /// One notice for all of them, and no rows. This tab found out these had gone by being told
    /// nothing about them, so it has no name and no picture for any — a row of grey placeholders
    /// would say less than the sentence does.
    private var discontinuedNotice: some View {
        SavedSectionHeader(
            title: "No Longer Available",
            icon: "xmark.circle",
            tint: .secondary,
            description: "One or more of your wishlist items has been discontinued. Sad, yes. But we thought you should know."
        )
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
