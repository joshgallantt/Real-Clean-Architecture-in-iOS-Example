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
        push(Destination.searchResults(query: query), tab: nil)
    }

    func openCategoryResults(category: CategorySlug) {
        push(Destination.categoryResults(category: category), tab: nil)
    }

    func openProductDetails(id: Int) {
        push(Destination.productDetails(id: id), tab: nil)
    }
}
