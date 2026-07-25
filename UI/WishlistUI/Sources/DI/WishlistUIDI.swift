//
//  WishlistUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import SwiftUI
import Wishlist
import Product
import WishlistUI

public struct WishlistUIDI {
    private let navigation: WishlistNavigation
    private let observeWishlist: ObserveWishlistUseCase
    private let productIsWishlisted: ProductIsWishlistedUseCase
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let getProduct: GetProductUseCase

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        productIsWishlisted: ProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        getProduct: GetProductUseCase
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.productIsWishlisted = productIsWishlisted
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.getProduct = getProduct
    }

    @MainActor
    public func button(productId: Int) -> some View {
        WishlistButtonView(
            productId: productId,
            productIsWishlisted: productIsWishlisted,
            addProductToWishlist: addProductToWishlist,
            removeProductFromWishlist: removeProductFromWishlist
        )
    }

    @MainActor
    public func mainView() -> some View {
        WishlistScreenView(
            viewModel: WishlistScreenViewModel(
                observeWishlist: observeWishlist,
                getProduct: getProduct
            ),
            navigation: navigation,
            wishlistButton: { productId in AnyView(button(productId: productId)) }
        )
    }
}
