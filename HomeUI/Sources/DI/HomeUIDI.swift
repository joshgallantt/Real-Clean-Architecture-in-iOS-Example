//
//  HomeUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import HomeUI

public struct HomeUIDI {
    private let navigation: HomeNavigation

    public init(navigation: HomeNavigation) {
        self.navigation = navigation
    }

    @MainActor
    public func mainView() -> some View {
        HomeScreenView(
            viewModel: HomeScreenViewModel(),
            navigation: navigation
        )
    }
    
    @MainActor
    public func detailView(id: UUID) -> some View {
        HomeDetailScreenView(id: id)
    }
}
