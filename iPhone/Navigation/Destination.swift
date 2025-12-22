//
//  Destination.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 22/12/2025.
//

import Foundation
import SwiftUI
import HomeUI
import HomeUIDI
import WishlistUI
import WishlistUIDI
import CartUI
import CartUIDI


public enum Destination: Hashable {
    case homeDetail(id: UUID)
    case wishlistDetail(id: UUID)
    case cartDetail(id: UUID)
    
    @ViewBuilder
    func makeView() -> some View {
        switch self {
        case .homeDetail(let id):
            Injector.shared.homeUIDI.detailView(id: id)
        case .wishlistDetail(let id):
            Injector.shared.wishlistUIDI.detailView(id: id)
        case .cartDetail(let id):
            Injector.shared.cartUIDI.detailView(id: id)
        }
    }
}

extension Navigator:
    HomeNavigation,
    WishlistNavigation,
    CartNavigation
{
    func openHomeDetail(id: UUID) {
        push(Destination.homeDetail(id: id))
    }
    
        
    func openWishlistDetail(id: UUID) {
        push(Destination.wishlistDetail(id: id))
    }
        
    func openCartDetail(id: UUID) {
        push(Destination.cartDetail(id: id))
    }
}
