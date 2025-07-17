//
//  FavoritesScreenViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 15/07/2025.
//

import Combine
import Foundation


final class FavoritesScreenViewModel: ObservableObject {
    private weak var navigation: FavoritesNavigation?

    init(navigation: FavoritesNavigation) {
        self.navigation = navigation
    }

    func openDetail(id: UUID) {
        navigation?.openFavoritesDetail(id: id)
    }

    func goToCartDetail(id: UUID) {
        navigation?.goToCartDetail(id: id)
    }
}
