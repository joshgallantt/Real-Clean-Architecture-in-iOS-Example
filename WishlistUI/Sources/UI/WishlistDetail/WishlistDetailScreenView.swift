//
//  WishlistDetailScreenView.swift
//  WishlistUI
//
//  Created by Josh Gallant on 19/07/2025.
//

import SwiftUI

public struct WishlistDetailScreenView: View {
    let id: UUID
    let navigation: WishlistNavigation
    
    public init(id: UUID, navigation: WishlistNavigation) {
        self.id = id
        self.navigation = navigation
    }
    
    public var body: some View {
        Text("Wishlist Detail for \(id.uuidString)")
    }
}
