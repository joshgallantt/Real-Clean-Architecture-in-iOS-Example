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

public struct WishlistUIDI {
    private let navigation: WishlistNavigation
    private let observeWishlist: ObserveWishlistUseCase
    private let productIsWishlisted: ProductIsWishlistedUseCase
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let getProductsByIds: GetProductsByIdsUseCase
    private let observeSession: ObserveSessionUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        productIsWishlisted: ProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        getProductsByIds: GetProductsByIdsUseCase,
        observeSession: ObserveSessionUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.productIsWishlisted = productIsWishlisted
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.getProductsByIds = getProductsByIds
        self.observeSession = observeSession
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
    }

    @MainActor
    public func button(productId: Int) -> some View {
        WishlistButtonView(
            viewModel: WishlistButtonViewModel(
                productId: productId,
                productIsWishlisted: self.productIsWishlisted,
                addProductToWishlist: self.addProductToWishlist,
                removeProductFromWishlist: self.removeProductFromWishlist,
                authPresenter: self.authPresenter,
                snackbarPresenter: self.snackbarPresenter
            )
        )
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
            authPresenter: authPresenter
        )
    }
}
