//
//  CartUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

public struct CartUIDI {
    private let navigation: CartNavigation

    public init(navigation: CartNavigation) {
        self.navigation = navigation
    }

    public func mainView() -> some View {
        let viewModel = CartScreenViewModel(navigation: navigation)
        return CartScreenView(viewModel: viewModel)
    }

    public func makeView(for destination: CartDestination) -> some View {
        switch destination {
        case .detail(let id):
            CartDetailScreenView(id: id)
        }
    }
}
