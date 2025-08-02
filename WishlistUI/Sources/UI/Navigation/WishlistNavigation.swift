//
//  WishlistNavigation.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation

public protocol WishlistNavigation: AnyObject {
    func openWishlistDetail(id: UUID)
    func goToCartDetail(id: UUID)
}
