//
//  FavoritesUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//


import SwiftUI

public struct FavoritesUIDI {
    private let navigation: FavoritesNavigation

    public init(navigation: FavoritesNavigation) {
        self.navigation = navigation
    }

    public func mainView() -> some View {
        let viewModel = FavoritesScreenViewModel(navigation: navigation)
        return FavoritesScreenView(viewModel: viewModel)
    }

    public func makeView(for destination: FavoritesDestination) -> some View {
        switch destination {
        case .detail(let id):
            FavoritesDetailScreenView(id: id)
        }
    }
}
