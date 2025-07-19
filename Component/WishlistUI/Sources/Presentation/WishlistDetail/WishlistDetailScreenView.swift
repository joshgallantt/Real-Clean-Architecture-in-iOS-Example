//
//  WishlistDetailScreenView.swift
//  WishlistUI
//
//  Created by Josh Gallant on 19/07/2025.
//

import SwiftUI

public struct WishlistDetailScreenView: View {
    let id: UUID
    
    public init(id: UUID) {
        self.id = id
    }
    
    public var body: some View {
        Text("Wishlist Detail for \(id.uuidString)")
    }
}
