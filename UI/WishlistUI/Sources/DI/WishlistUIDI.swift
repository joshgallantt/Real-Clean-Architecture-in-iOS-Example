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
    private let isInWishlist: IsInWishlistUseCase
    private let addToWishlist: AddToWishlistUseCase
    private let removeFromWishlist: RemoveFromWishlistUseCase
    private let getProduct: GetProductUseCase

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        isInWishlist: IsInWishlistUseCase,
        addToWishlist: AddToWishlistUseCase,
        removeFromWishlist: RemoveFromWishlistUseCase,
        getProduct: GetProductUseCase
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.isInWishlist = isInWishlist
        self.addToWishlist = addToWishlist
        self.removeFromWishlist = removeFromWishlist
        self.getProduct = getProduct
    }

    @MainActor
    public func button(productId: Int) -> some View {
        WishlistButtonView(
            productId: productId,
            isInWishlistUseCase: isInWishlist,
            addToWishlistUseCase: addToWishlist,
            removeFromWishlistUseCase: removeFromWishlist
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
