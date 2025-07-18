//
//  FavoritesScreenViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 15/07/2025.
//

import Combine
import Foundation


final class FavoritesScreenViewModel: ObservableObject {
    func didSelectFavorite(id: UUID) {
        // Any non-navigation side effects, e.g. analytics or state mutation
    }

    func didSelectGoToCart(id: UUID) {
        // Any business logic for this action
    }
}

