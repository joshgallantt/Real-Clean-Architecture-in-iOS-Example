import Foundation
import SwiftUI
import Product
import HomeUI
import SearchUI
import SearchUIDI
import WishlistUI
import BagUI
import ProductUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: every route in one place, in
/// the only layer that may know all the features. It also declares navigation policy — which
/// destinations require an account — so the rule sits beside the routes rather than in each screen.
public enum Destination: Hashable {
    case catalog(CatalogFilter)
    case productDetails(ProductReference)

    public enum ProductReference: Hashable {
        case id(ProductID)
        case product(Product)
    }

    var requiresAuthentication: Bool {
        switch self {
        case .catalog, .productDetails:
            return false
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
        }
    }
}

extension Navigator: HomeNavigation, SearchNavigation, WishlistNavigation, BagNavigation {
    func openCatalog(filter: CatalogFilter) {
        open(.catalog(filter))
    }

    func openProductDetails(product: Product) {
        open(.productDetails(.product(product)))
    }

    func openProductDetails(id: ProductID) {
        open(.productDetails(.id(id)))
    }

    func switchToBagTab() {
        bagPath = NavigationPath()
        selectedTab = .bag
    }
}
