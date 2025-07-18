//
//  FavoritesScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

struct FavoritesScreenView: View {
    @ObservedObject var viewModel: FavoritesScreenViewModel
    let navigation: FavoritesNavigation

    var body: some View {
        VStack {
            Text("Favorites Screen")
            Button("Open Favorites Detail") {
                let id = UUID()
                viewModel.didSelectFavorite(id: id)
                navigation.openFavoritesDetail(id: id)
            }
            Button("Go to Cart Detail") {
                let id = UUID()
                viewModel.didSelectGoToCart(id: id)
                navigation.goToCartDetail(id: id)
            }
        }
    }
}


struct FavoritesDetailScreenView: View {
    let id: UUID
    var body: some View {
        Text("Favorites Detail for \(id.uuidString)")
    }
}
