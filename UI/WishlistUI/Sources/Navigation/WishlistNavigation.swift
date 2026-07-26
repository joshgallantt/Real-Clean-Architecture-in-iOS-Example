//
//  WishlistNavigation.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation
import Product

public protocol WishlistNavigation: AnyObject {
    func openProductDetails(product: Product)
}
