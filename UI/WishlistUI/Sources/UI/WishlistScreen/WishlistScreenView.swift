import SwiftUI
import Product
import ProductUI
import Tracking
import TrackingUI

/// The tab a shopper keeps an eye on things from. Three lists: what they are still waiting on, what
/// has come back, and what they saved because they liked it. The first two are the same set of asks
/// told apart by what the shop says today — not by anything the app has to have been told.
///
/// Each shows a handful, offers the rest, and can be emptied in one go.
public struct WishlistScreenView: View {
    @Environment(\.trackingContext) private var trackingContext

    let session: WishlistScreenViewModel
    let faves: SavedProductsViewModel
    let waitlist: AlertedProductsViewModel
    let backInStock: AlertedProductsViewModel

    let navigation: WishlistNavigation

    /// What each card offers, per list. The trailing one manages the list — a minus on the two
    /// alert rows, a heart on the faves — and the leading one buys, where buying is possible.
    let waitlistAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView)
    let backInStockAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView)
    let favesAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView)

    public init(
        session: WishlistScreenViewModel,
        faves: SavedProductsViewModel,
        waitlist: AlertedProductsViewModel,
        backInStock: AlertedProductsViewModel,
        navigation: WishlistNavigation,
        waitlistAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView),
        backInStockAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView),
        favesAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView)
    ) {
        self.session = session
        self.faves = faves
        self.waitlist = waitlist
        self.backInStock = backInStock
        self.navigation = navigation
        self.waitlistAccessories = waitlistAccessories
        self.backInStockAccessories = backInStockAccessories
        self.favesAccessories = favesAccessories
    }

    public var body: some View {
        Group {
            if session.isAuthenticated {
                lists
            } else {
                guestPrompt
            }
        }
        .onScreenAppear { session.didAppear(in: $0) }
        .task {
            session.onAppear()
            faves.onAppear(in: trackingContext)
            async let waiting: Void = waitlist.onAppear(in: trackingContext)
            async let restocked: Void = backInStock.onAppear(in: trackingContext)
            _ = await (waiting, restocked)
        }
    }

    private var lists: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                SavedProductsCarousel(
                    products: waitlist.products,
                    total: waitlist.count,
                    onClear: { waitlist.didConfirmClear(in: $0) },
                    title: "Waitlist",
                    icon: "bell.fill",
                    tint: .orange,
                    description: "Sold out. You asked, so we'll tell you.",
                    emptyMessage: nil,
                    onSelect: { waitlist.didSelect($0, in: $1) },
                    onSeen: { waitlist.didSee($0, in: $1) },
                    onViewAll: { session.didTapViewAll(WishlistTrackingPlan.waitlist, in: $0); navigation.openAllWaitlist() },
                    accessory: waitlistAccessories.trailing,
                    leadingAccessory: waitlistAccessories.leading
                )
                .trackingList(WishlistTrackingPlan.waitlist)

                /// The same asks as above, split by what the shop says today. A shopper does not
                /// need telling twice that something is still sold out, and does need telling once
                /// that it is not.
                SavedProductsCarousel(
                    products: backInStock.products,
                    total: backInStock.count,
                    onClear: { backInStock.didConfirmClear(in: $0) },
                    title: "Back in Stock",
                    icon: "sparkles",
                    tint: .green,
                    description: "You asked, they're back. Get in before they go again.",
                    emptyMessage: nil,
                    onSelect: { backInStock.didSelect($0, in: $1) },
                    onSeen: { backInStock.didSee($0, in: $1) },
                    onViewAll: { session.didTapViewAll(WishlistTrackingPlan.backInStock, in: $0); navigation.openAllBackInStock() },
                    accessory: backInStockAccessories.trailing,
                    leadingAccessory: backInStockAccessories.leading
                )
                .trackingList(WishlistTrackingPlan.backInStock)

                SavedProductsCarousel(
                    products: faves.products,
                    total: faves.savedCount,
                    onClear: { faves.didConfirmClear(in: $0) },
                    title: "My Faves",
                    icon: "heart.fill",
                    tint: .accentColor,
                    description: "Everything you've saved. No rush.",
                    emptyMessage: "Tap the heart on anything you like the look of.",
                    onSelect: { faves.didSelect($0, in: $1) },
                    onSeen: { faves.didSee($0, in: $1) },
                    onViewAll: { session.didTapViewAll(WishlistTrackingPlan.faves, in: $0); navigation.openAllFaves() },
                    accessory: favesAccessories.trailing,
                    leadingAccessory: favesAccessories.leading
                )
                .trackingList(WishlistTrackingPlan.faves)
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
                session.didTapSignIn(in: trackingContext)
            } label: {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
