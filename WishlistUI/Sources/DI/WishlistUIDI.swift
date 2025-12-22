//
//  WishlistUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//


import SwiftUI
import WishlistUI

public struct WishlistUIDI {
    private let navigation: WishlistNavigation

    public init(navigation: WishlistNavigation) {
        self.navigation = navigation
    }

    @MainActor
    public func mainView() -> some View {
        WishlistScreenView(
            viewModel: WishlistScreenViewModel(),
            navigation: navigation
        )
    }
    
    @MainActor
    public func detailView(id: UUID) -> some View {
        WishlistDetailScreenView(id: id, navigation: navigation)
    }
}
