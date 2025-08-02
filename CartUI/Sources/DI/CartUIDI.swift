//
//  CartUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import CartUI

public struct CartUIDI {
    private let navigation: CartNavigation

    public init(navigation: CartNavigation) {
        self.navigation = navigation
    }

    @MainActor
    public func mainView() -> some View {
        let viewModel = CartScreenViewModel()
        return CartScreenView(viewModel: viewModel, navigation: navigation)
    }

    @MainActor
    public func makeView(for destination: CartDestination) -> some View {
        switch destination {
        case .detail(let id):
            CartDetailScreenView(id: id)
        }
    }
}
