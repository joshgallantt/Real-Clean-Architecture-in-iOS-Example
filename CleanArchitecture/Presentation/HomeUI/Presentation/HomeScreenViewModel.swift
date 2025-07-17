//
//  HomeScreenViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 15/07/2025.
//

import Combine
import Foundation

final class HomeScreenViewModel: ObservableObject {
    private weak var navigation: HomeNavigation?

    init(navigation: HomeNavigation) {
        self.navigation = navigation
    }

    func openDetail(id: UUID) {
        navigation?.openHomeDetail(id: id)
    }

    func goToFavoritesDetail(id: UUID) {
        navigation?.goToFavoritesDetail(id: id)
    }
}
