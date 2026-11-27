import SwiftUI
import Product
import ProductUI
import Tracking
import TrackingUI

/// The tab a shopper keeps an eye on things from. Their faves are this feature's; above them sit
/// their stock alerts, drawn by the feature that owns them and handed in already built — so this
/// screen places the section, or leaves it out when the shopper has switched it off, and never
/// learns there is a stock alert domain.
public struct WishlistScreenView: View {
    @Environment(\.trackingContext) private var trackingContext

    let session: WishlistScreenViewModel
    let faves: SavedProductsViewModel

    let navigation: WishlistNavigation

    /// The shopper's stock alerts, as one view. It takes no room while it has nothing to show, so
    /// the faves start at the top for a shopper with no alerts.
    let stockAlertSection: AnyView

    /// What each fave's card offers: a heart to manage the list and, leading, a way to buy.
    let favesAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView)

    public init(
        session: WishlistScreenViewModel,
        faves: SavedProductsViewModel,
        navigation: WishlistNavigation,
        stockAlertSection: AnyView,
        favesAccessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView)
    ) {
        self.session = session
        self.faves = faves
        self.navigation = navigation
        self.stockAlertSection = stockAlertSection
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
        }
    }

    private var lists: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if session.showsStockAlerts {
                    stockAlertSection
                }

                ProductCarouselSection(
                    products: faves.products,
                    total: faves.savedCount,
                    onClear: { faves.didConfirmClear(in: $0) },
                    title: "My Faves",
                    icon: "heart.fill",
                    tint: .accentColor,
                    description: "Everything you've saved. No rush.",
                    whenEmpty: .explained("Tap the heart on anything you like the look of."),
                    onSelect: { faves.didSelect($0, in: $1) },
                    onSeen: { faves.didSee($0, in: $1) },
                    onViewAll: { session.didTapViewAllFaves(in: $0); navigation.openAllFaves() },
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
