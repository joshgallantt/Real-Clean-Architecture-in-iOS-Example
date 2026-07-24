import SwiftUI
import HomeUI
import Product

public struct HomeUIDI {
    private let navigation: HomeNavigation
    private let getProducts: GetProductsUseCase

    public init(navigation: HomeNavigation, getProducts: GetProductsUseCase) {
        self.navigation = navigation
        self.getProducts = getProducts
    }

    @MainActor
    public func mainView() -> some View {
        HomeScreenView(
            viewModel: HomeScreenViewModel(getProducts: getProducts),
            navigation: navigation
        )
    }
}
