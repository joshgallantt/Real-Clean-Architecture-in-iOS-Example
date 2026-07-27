//
//  WishlistUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import SwiftUI
import Wishlist
import Product
import Session
import AuthUI
import SnackbarUI
import WishlistUI
import BagUIDI
import SharedUIDI

public struct WishlistUIDI {
    private let navigation: WishlistNavigation
    private let observeWishlist: ObserveWishlistUseCase
    private let getProductsByIds: GetProductsByIdsUseCase
    private let observeSession: ObserveSessionUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let bagUIDI: BagUIDI
    private let sharedUIDI: SharedUIDI

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        getProductsByIds: GetProductsByIdsUseCase,
        observeSession: ObserveSessionUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        bagUIDI: BagUIDI,
        sharedUIDI: SharedUIDI
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.getProductsByIds = getProductsByIds
        self.observeSession = observeSession
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.bagUIDI = bagUIDI
        self.sharedUIDI = sharedUIDI
    }

    @MainActor
    public func button(productId: Int) -> some View {
        sharedUIDI.wishlistButton(productId: productId)
    }

    @MainActor
    public func mainView() -> some View {
        WishlistScreenView(
            viewModel: WishlistScreenViewModel(
                observeWishlist: observeWishlist,
                getProductsByIds: getProductsByIds,
                observeSession: observeSession,
                snackbar: snackbarPresenter
            ),
            navigation: navigation,
            wishlistButton: { productId in AnyView(button(productId: productId)) },
            bagButton: { productId in AnyView(bagUIDI.button(productId: productId)) },
            authPresenter: authPresenter
        )
    }
}
