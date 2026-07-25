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
    case searchResults(query: String)
    case categoryResults(category: CategorySlug)
    case productDetails(id: Int)

    /// Navigation policy: destinations that require an authenticated session.
    /// `Navigator.open` routes these through the auth gate before pushing.
    var requiresAuthentication: Bool {
        switch self {
        case .searchResults, .categoryResults, .productDetails:
            return false
        }
    }

    @ViewBuilder
    func makeView() -> some View {
        switch self {
        case .searchResults(let query):
            Injector.shared.searchUIDI.searchResultsView(query: query)
        case .categoryResults(let category):
            Injector.shared.searchUIDI.categoryResultsView(category: category)
        case .productDetails(let id):
            Injector.shared.productUIDI.detailView(id: id)
        }
    }
}

extension Navigator:
    HomeNavigation,
    SearchNavigation,
    WishlistNavigation,
    BagNavigation
{
    func openSearchResults(query: String) {
        open(.searchResults(query: query))
    }

    func openCategoryResults(category: CategorySlug) {
        open(.categoryResults(category: category))
    }

    func openProductDetails(id: Int) {
        open(.productDetails(id: id))
    }
}
