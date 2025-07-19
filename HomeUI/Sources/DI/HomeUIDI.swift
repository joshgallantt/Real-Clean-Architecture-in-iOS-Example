//
//  HomeUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import HomePresentation

public struct HomeUIDI {
    private let navigation: HomeNavigation

    public init(navigation: HomeNavigation) {
        self.navigation = navigation
    }

    @MainActor
    public func mainView() -> some View {
        let viewModel = HomeScreenViewModel()
        return HomeScreenView(viewModel: viewModel, navigation: navigation)
    }

    @MainActor
    public func makeView(for destination: HomeDestination) -> some View {
        switch destination {
        case .detail(let id):
            HomeDetailScreenView(id: id)
        }
    }
}
