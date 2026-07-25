import SwiftUI
import HomeUI
import Product
import SnackbarUI

public struct HomeUIDI {
    private let navigation: HomeNavigation
    private let getProducts: GetProductsUseCase
    private let snackbar: SnackbarPresenting

    public init(navigation: HomeNavigation, getProducts: GetProductsUseCase, snackbar: SnackbarPresenting) {
        self.navigation = navigation
        self.getProducts = getProducts
        self.snackbar = snackbar
    }

    @MainActor
    public func mainView() -> some View {
        HomeScreenView(
            viewModel: HomeScreenViewModel(getProducts: getProducts, snackbar: snackbar),
            navigation: navigation
        )
    }
}
