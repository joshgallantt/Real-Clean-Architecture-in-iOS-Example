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
        CartScreenView(
            viewModel: CartScreenViewModel(),
            navigation: navigation
        )
    }
    
    @MainActor
    public func detailView(id: UUID) -> some View {
        CartDetailScreenView(id: id)
    }
}
