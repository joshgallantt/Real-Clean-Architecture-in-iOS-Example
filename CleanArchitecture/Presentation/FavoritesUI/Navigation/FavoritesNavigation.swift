//
//  FavoritesNavigation.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation

public protocol FavoritesNavigation: AnyObject {
    func openFavoritesDetail(id: UUID)
    func goToCartDetail(id: UUID)
}
