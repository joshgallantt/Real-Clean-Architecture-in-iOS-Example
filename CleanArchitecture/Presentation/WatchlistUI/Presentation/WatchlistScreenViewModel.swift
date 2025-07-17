//
//  CartScreenViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 15/07/2025.
//

import Foundation
import Combine

public final class CartScreenViewModel: ObservableObject {
    private weak var navigation: CartNavigation?

    public init(navigation: CartNavigation) {
        self.navigation = navigation
    }

    public func openDetail(id: UUID) {
        navigation?.openCartDetail(id: id)
    }

    public func goToHomeDetail(id: UUID) {
        navigation?.openHomeDetail(id: id)
    }
}
