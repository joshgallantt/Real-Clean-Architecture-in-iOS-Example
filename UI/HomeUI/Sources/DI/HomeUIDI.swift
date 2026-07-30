import SwiftUI
import HomeUI
import Product
import SnackbarUI

public struct HomeUIDI {
    private let navigation: HomeNavigation
    private let browseCatalog: BrowseCatalogUseCase
    private let snackbar: SnackbarPresenting

    public init(navigation: HomeNavigation, browseCatalog: BrowseCatalogUseCase, snackbar: SnackbarPresenting) {
        self.navigation = navigation
        self.browseCatalog = browseCatalog
        self.snackbar = snackbar
    }

    @MainActor
    public func mainView() -> some View {
        HomeScreenView(
            viewModel: HomeScreenViewModel(browseCatalog: browseCatalog, snackbar: snackbar),
            navigation: navigation
        )
    }
}
