import SwiftUI
import Product
import ProductUI
import AuthUI

/// The tab a shopper keeps an eye on things from. Three lists: what they are still waiting on, what
/// has come back, and what they saved because they liked it. The first two are the same set of asks
/// told apart by what the shop says today — not by anything the app has to have been told.
///
/// Each shows a handful, offers the rest, and can be emptied in one go.
public struct WishlistScreenView: View {
    @ObservedObject var session: WishlistScreenViewModel
    @ObservedObject var faves: SavedProductsViewModel
    @ObservedObject var waitlist: AlertedProductsViewModel
    @ObservedObject var backInStock: AlertedProductsViewModel

    let navigation: WishlistNavigation

    /// What each card offers, per list. The trailing one manages the list — a minus on the two
    /// alert rows, a heart on the faves — and the leading one buys, where buying is possible.
    let waitlistAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView)
    let backInStockAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView)
    let favesAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView)

    let authPresenter: AuthPresenting

    public init(
        session: WishlistScreenViewModel,
        faves: SavedProductsViewModel,
        waitlist: AlertedProductsViewModel,
        backInStock: AlertedProductsViewModel,
        navigation: WishlistNavigation,
        waitlistAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView),
        backInStockAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView),
        favesAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView),
        authPresenter: AuthPresenting
    ) {
        self.session = session
        self.faves = faves
        self.waitlist = waitlist
        self.backInStock = backInStock
        self.navigation = navigation
        self.waitlistAccessories = waitlistAccessories
        self.backInStockAccessories = backInStockAccessories
        self.favesAccessories = favesAccessories
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
            session.onAppear()
            faves.onAppear()
            waitlist.onAppear()
            backInStock.onAppear()
        }
    }

    private var lists: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                SavedProductsCarousel(
                    products: waitlist.products,
                    total: waitlist.count,
                    onClear: { waitlist.didConfirmClear() },
                    title: "Waitlist",
                    icon: "bell.fill",
                    tint: .orange,
                    description: "Sold out. You asked, so we'll tell you.",
                    emptyMessage: "Hit the bell on anything sold out and it waits here.",
                    onSelect: { navigation.openProductDetails(product: $0) },
                    onViewAll: { navigation.openAllWaitlist() },
                    accessory: waitlistAccessories.trailing,
                    leadingAccessory: waitlistAccessories.leading
                )

                /// The same asks as above, split by what the shop says today. A shopper does not
                /// need telling twice that something is still sold out, and does need telling once
                /// that it is not.
                SavedProductsCarousel(
                    products: backInStock.products,
                    total: backInStock.count,
                    onClear: { backInStock.didConfirmClear() },
                    title: "Back in Stock",
                    icon: "sparkles",
                    tint: .green,
                    description: "You asked, they're back. Get in before they go again.",
                    emptyMessage: "Anything you're waiting on lands here the second it's back.",
                    onSelect: { navigation.openProductDetails(product: $0) },
                    onViewAll: { navigation.openAllBackInStock() },
                    accessory: backInStockAccessories.trailing,
                    leadingAccessory: backInStockAccessories.leading
                )

                SavedProductsCarousel(
                    products: faves.products,
                    total: faves.savedCount,
                    onClear: { faves.didConfirmClear() },
                    title: "My Faves",
                    icon: "heart.fill",
                    tint: .accentColor,
                    description: "Everything you've saved. No rush.",
                    emptyMessage: "Tap the heart on anything you like the look of.",
                    onSelect: { navigation.openProductDetails(product: $0) },
                    onViewAll: { navigation.openAllFaves() },
                    accessory: favesAccessories.trailing,
                    leadingAccessory: favesAccessories.leading
                )
            }
            .padding(.vertical)
        }
    }



    private var guestPrompt: some View {
        ContentUnavailableView {
            Label("Keep Your Faves", systemImage: "heart")
        } description: {
            Text("Sign in and everything you save sticks around.")
        } actions: {
            Button {
                Task {
                    await authPresenter.show(AuthenticationPrompt(
                        title: "Keep Your Faves",
                        message: "Sign in and everything you save sticks around.",
                        icon: "heart.fill"
                    ))
                }
            } label: {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
