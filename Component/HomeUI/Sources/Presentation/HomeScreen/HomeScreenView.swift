//
//  HomeScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import Combine

public struct HomeScreenView: View {
    @ObservedObject var viewModel: HomeScreenViewModel
    let navigation: HomeNavigation
    
    public init(viewModel: HomeScreenViewModel, navigation: HomeNavigation) {
        self.viewModel = viewModel
        self.navigation = navigation
    }

    public var body: some View {
        VStack {
            Text("Home Screen")
            Button("Open Home Detail") {
                let id = UUID()
                viewModel.didSelectHomeDetail(id: id)
                navigation.openHomeDetail(id: id)
            }
            Button("Go to Wishlist Detail") {
                let id = UUID()
                viewModel.didSelectGoToWishlist(id: id)
                navigation.goToWishlistDetail(id: id)
            }
        }
    }
}
