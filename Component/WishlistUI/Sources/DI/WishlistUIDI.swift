//
//  WishlistUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//


import SwiftUI
import WishlistPresentation

public struct WishlistUIDI {
    private let navigation: WishlistNavigation

    public init(navigation: WishlistNavigation) {
        self.navigation = navigation
    }

    @MainActor
    public func mainView() -> some View {
        let viewModel = WishlistScreenViewModel()
        return WishlistScreenView(viewModel: viewModel, navigation: navigation)
    }

    @MainActor
    public func makeView(for destination: WishlistDestination) -> some View {
        switch destination {
        case .detail(let id):
            WishlistDetailScreenView(id: id)
        }
    }
}
