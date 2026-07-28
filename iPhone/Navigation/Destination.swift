//
//  Destination.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 22/12/2025.
//

import Foundation
import SwiftUI
import Product
import HomeUI
import SearchUI
import SearchUIDI
import WishlistUI
import BagUI
import ProductUIDI

public enum Destination: Hashable {
    case catalog(CatalogFilter)
    case productDetails(ProductReference)

    /// Either the bare id (fetched on appear) or an already-loaded model
    /// (e.g. from a product grid, which skips the fetch entirely).
    public enum ProductReference: Hashable {
        case id(Int)
        case product(Product)
    }

    /// Navigation policy: destinations that require an authenticated session.
    /// `Navigator.open` routes these through the auth gate before pushing.
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
            Injector.shared.searchUIDI.catalogResultsView(filter: filter)
        case .productDetails(.id(let id)):
            Injector.shared.productUIDI.detailView(id: id)
        case .productDetails(.product(let product)):
            Injector.shared.productUIDI.detailView(product: product)
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

    func switchToBagTab() {
        bagPath = NavigationPath()
        selectedTab = .bag
    }
}
