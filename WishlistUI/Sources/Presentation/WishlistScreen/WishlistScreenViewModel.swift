//
//  WishlistScreenViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 15/07/2025.
//

import Combine
import Foundation


public final class WishlistScreenViewModel: ObservableObject {
    public init() {}
    
    func didSelectWishlistItem(id: UUID) {
        // Any non-navigation side effects, e.g. analytics or state mutation
    }

    func didSelectGoToCart(id: UUID) {
        // Any business logic for this action
    }
}

