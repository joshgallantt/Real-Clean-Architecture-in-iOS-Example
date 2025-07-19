//
//  WishlistScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

public struct WishlistScreenView: View {
    @ObservedObject var viewModel: WishlistScreenViewModel
    let navigation: WishlistNavigation
    
    public init(viewModel: WishlistScreenViewModel, navigation: WishlistNavigation) {
        self.viewModel = viewModel
        self.navigation = navigation
    }

    public var body: some View {
        VStack {
            Text("Wishlist Screen")
            Button("Open Wishlist Detail") {
                let id = UUID()
                viewModel.didSelectWishlistItem(id: id)
                navigation.openWishlistDetail(id: id)
            }
            Button("Go to Cart Detail") {
                let id = UUID()
                viewModel.didSelectGoToCart(id: id)
                navigation.goToCartDetail(id: id)
            }
        }
    }
}
