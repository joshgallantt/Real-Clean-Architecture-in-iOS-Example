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
            Button("Go to Favorites Detail") {
                let id = UUID()
                viewModel.didSelectGoToFavorites(id: id)
                navigation.goToFavoritesDetail(id: id)
            }
        }
    }
}
