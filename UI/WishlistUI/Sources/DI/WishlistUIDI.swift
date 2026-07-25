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
import AuthGate
import WishlistUI

public struct WishlistUIDI {
    private let navigation: WishlistNavigation
    private let observeWishlist: ObserveWishlistUseCase
    private let productIsWishlisted: ProductIsWishlistedUseCase
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let getProduct: GetProductUseCase
    private let observeSession: ObserveSessionUseCase
    private let authGate: AuthGate

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        productIsWishlisted: ProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        getProduct: GetProductUseCase,
        observeSession: ObserveSessionUseCase,
        authGate: AuthGate
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.productIsWishlisted = productIsWishlisted
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.getProduct = getProduct
        self.observeSession = observeSession
        self.authGate = authGate
    }

    @MainActor
    public func button(productId: Int) -> some View {
        WishlistButtonView(
            productId: productId,
            productIsWishlisted: productIsWishlisted,
            addProductToWishlist: addProductToWishlist,
            removeProductFromWishlist: removeProductFromWishlist,
            authGate: authGate
        )
    }

    @MainActor
    public func mainView() -> some View {
        WishlistScreenView(
            viewModel: WishlistScreenViewModel(
                observeWishlist: observeWishlist,
                getProduct: getProduct,
                observeSession: observeSession
            ),
            navigation: navigation,
            wishlistButton: { productId in AnyView(button(productId: productId)) },
            authGate: authGate
        )
    }
}
