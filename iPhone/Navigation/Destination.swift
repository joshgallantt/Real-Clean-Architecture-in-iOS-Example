import Foundation
import SwiftUI
import Product
import HomeUI
import SearchUI
import SearchUIDI
import WishlistUI
import WishlistUIDI
import BagUI
import OrderUIDI
import ProductActionsUI
import ProductUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: every route in one place, in
/// the only layer that may know all the features. It also declares navigation policy — which
/// destinations require an account — so the rule sits beside the routes rather than in each screen.
public enum Destination: Hashable {
    case catalog(CatalogFilter)
    case productDetails(ProductReference)
    case orderHistory
    case allFaves
    case allNotifyMe

    public enum ProductReference: Hashable {
        case id(ProductID)
        case product(Product)
    }

    var requiresAuthentication: Bool {
        switch self {
        case .catalog, .productDetails:
            return false
        /// Everything a shopper keeps. Orders, faves and the things they are waiting on all belong
        /// to somebody, so there is nothing to show a guest — and the prompt happens here, where
        /// the policy already lives, rather than being remembered by each screen.
        case .orderHistory, .allFaves, .allNotifyMe:
            return true
        }
    }

    @ViewBuilder
    func makeView() -> some View {
        switch self {
        case .catalog(let filter):
            CompositionRoot.shared.presentation.search.catalogResultsView(filter: filter)
        case .productDetails(.id(let id)):
            CompositionRoot.shared.presentation.product.detailView(id: id)
        case .productDetails(.product(let product)):
            CompositionRoot.shared.presentation.product.detailView(product: product)
        case .orderHistory:
            CompositionRoot.shared.presentation.order.historyView()
        case .allFaves:
            CompositionRoot.shared.presentation.wishlist.allFavesView()
        case .allNotifyMe:
            CompositionRoot.shared.presentation.wishlist.allNotifyMeView()
        }
    }
}

extension Navigator: HomeNavigation, SearchNavigation, WishlistNavigation, BagNavigation, ProductActionsNavigation {
    func openCatalog(filter: CatalogFilter) {
        open(.catalog(filter))
    }

    func openProductDetails(product: Product) {
        open(.productDetails(.product(product)))
    }

    func openProductDetails(id: ProductID) {
        open(.productDetails(.id(id)))
    }

    func openAllFaves() {
        open(.allFaves)
    }

    func openAllNotifyMe() {
        open(.allNotifyMe)
    }

    func switchToBagTab() {
        bagPath = NavigationPath()
        selectedTab = .bag
    }
}
